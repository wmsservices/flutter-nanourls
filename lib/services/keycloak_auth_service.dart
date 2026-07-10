import 'dart:async';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../entities/user.dart';
import 'api_service.dart';
import 'session_manager.dart';

// Serviço responsável pelo fluxo OAuth2/OIDC com o Keycloak
// (Authorization Code + PKCE, o "Standard Flow" do Keycloak).
//
// O access token obtido é publicado no SessionManager, então o ApiService
// existente continua montando o header "Authorization: Bearer ..." sem alterações.
class KeycloakAuthService {
  static final KeycloakAuthService _instance = KeycloakAuthService._internal();

  factory KeycloakAuthService() {
    return _instance;
  }

  KeycloakAuthService._internal();

  // Configurações do servidor SSO
  static const String _issuer = 'https://sso.nanourls.com/realms/nanourls';
  static const String _clientId = 'nanourls-app';
  static const String _redirectUrl = 'com.nanourls.app://oauthredirect';
  static const String _discoveryUrl = '$_issuer/.well-known/openid-configuration';

  // "offline_access" habilita o refresh token de longa duração para manter o usuário logado
  static const List<String> _scopes = ['openid', 'profile', 'email', 'offline_access'];

  // Chaves do armazenamento seguro (Keychain no iOS / Keystore no Android)
  static const String _refreshTokenKey = 'kc_refresh_token';
  static const String _idTokenKey = 'kc_id_token';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final SessionManager _sessionManager = SessionManager();

  String? _accessToken;
  DateTime? _accessTokenExpiry;
  Timer? _refreshTimer;

  // Abre a tela de login do Keycloak no navegador do sistema (Custom Tab / ASWebAuthenticationSession),
  // executa o Authorization Code Flow com PKCE e hidrata a sessão do app.
  // [idpHint] é o alias do provedor social (ex.: "google", "apple") obtido via
  // ApiService.fetchIdentityProviders(); quando informado, pula a tela de seleção
  // de provedor do Keycloak e vai direto para o provedor escolhido pelo usuário
  Future<User> login({String? idpHint}) async {
    final AuthorizationTokenResponse response = await _appAuth
        .authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            _clientId,
            _redirectUrl,
            discoveryUrl: _discoveryUrl,
            scopes: _scopes,
            // Evita o redirect "silencioso" (sessão já existente no navegador do
            // sistema): no Android, um retorno rápido demais do Custom Tab é
            // interpretado erroneamente pelo AppAuth como cancelamento do usuário
            // (race condition conhecida da lib nativa).
            promptValues: const ['login'],
            additionalParameters: idpHint == null ? null : {'kc_idp_hint': idpHint},
          ),
        )
        // Rede de segurança para o caso (visto em campo, Android) de o Custom Tab
        // nunca devolver o controle pro app depois do redirect do Keycloak: sem
        // timeout, esse await fica pendente pra sempre e a tela de login trava
        // num loading infinito. Com timeout, vira uma exceção normal, capturada
        // pelo catch/finally de quem chama login() (login_screen/sign_up_screen),
        // que já sabe recuperar o estado de loading e mostrar erro
        .timeout(
          const Duration(seconds: 90),
          onTimeout: () => throw TimeoutException(
            'Tempo esgotado aguardando o retorno do login SSO.',
          ),
        );

    await _applyTokenResponse(response);
    return _loadLocalUser();
  }

  // Restaura a sessão na abertura do app usando o refresh token persistido.
  // Retorna false quando não há sessão ou o refresh token expirou (exige novo login)
  Future<bool> restoreSession() async {
    final refreshed = await _refreshAccessToken();
    if (!refreshed) return false;

    try {
      await _loadLocalUser();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Retorna um access token válido, renovando com o refresh token quando necessário.
  // Útil para chamadas pontuais fora do ciclo de renovação automática
  Future<String?> getValidAccessToken() async {
    final expiry = _accessTokenExpiry;
    final isValid = _accessToken != null &&
        expiry != null &&
        DateTime.now().isBefore(expiry.subtract(const Duration(seconds: 30)));

    if (isValid) return _accessToken;

    await _refreshAccessToken();
    return _accessToken;
  }

  // Encerra a sessão no Keycloak (SSO logout) e limpa os tokens locais
  Future<void> logout() async {
    final idToken = await _secureStorage.read(key: _idTokenKey);

    try {
      if (idToken != null) {
        await _appAuth.endSession(
          EndSessionRequest(
            idTokenHint: idToken,
            postLogoutRedirectUrl: _redirectUrl,
            discoveryUrl: _discoveryUrl,
          ),
        );
      }
    } catch (_) {
      // Falha ao encerrar no servidor não impede a limpeza local da sessão
    }

    await _clearLocalTokens();
    _sessionManager.clearSession();
  }

  // Troca o refresh token persistido por um novo access token
  Future<bool> _refreshAccessToken() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;

    try {
      final TokenResponse response = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUrl,
          discoveryUrl: _discoveryUrl,
          refreshToken: refreshToken,
          scopes: _scopes,
        ),
      );

      await _applyTokenResponse(response);
      return true;
    } catch (_) {
      // Refresh token inválido/expirado: limpa tudo e exige novo login
      await _clearLocalTokens();
      return false;
    }
  }

  // Guarda os tokens, publica o access token no SessionManager e agenda a renovação
  Future<void> _applyTokenResponse(TokenResponse response) async {
    final accessToken = response.accessToken;
    if (accessToken == null) {
      throw Exception('O Keycloak não retornou um access token.');
    }

    _accessToken = accessToken;
    _accessTokenExpiry = response.accessTokenExpirationDateTime;

    // O refresh token rotaciona a cada uso: sempre persiste o mais recente
    if (response.refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: response.refreshToken);
    }
    if (response.idToken != null) {
      await _secureStorage.write(key: _idTokenKey, value: response.idToken);
    }

    // Mantém o header Authorization do ApiService sempre com o token vigente
    _sessionManager.updateToken(accessToken);

    _scheduleProactiveRefresh();
  }

  // Carrega o perfil local do usuário. A primeira chamada autenticada dispara
  // o provisionamento Just-in-Time na API (criação do usuário local, se necessário)
  Future<User> _loadLocalUser() async {
    final user = await ApiService().fetchCurrentUser();
    _sessionManager.saveSession(_accessToken!, user);
    return user;
  }

  // Renova o access token um minuto antes de expirar, sem interromper o usuário
  void _scheduleProactiveRefresh() {
    _refreshTimer?.cancel();
    final expiry = _accessTokenExpiry;
    if (expiry == null) return;

    final refreshIn = expiry.difference(DateTime.now()) - const Duration(minutes: 1);
    _refreshTimer = Timer(
      refreshIn.isNegative ? const Duration(seconds: 5) : refreshIn,
      () => _refreshAccessToken(),
    );
  }

  Future<void> _clearLocalTokens() async {
    _refreshTimer?.cancel();
    _accessToken = null;
    _accessTokenExpiry = null;
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _idTokenKey);
  }
}
