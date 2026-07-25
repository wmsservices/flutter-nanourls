import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../entities/user.dart';
import '../entities/nano_url.dart';
import '../entities/plan.dart';
import '../entities/device.dart';
import '../dtos/dashboard_data_dto.dart';
import '../dtos/my_analytics_dto.dart';
import '../dtos/identity_provider_dto.dart';
import 'session_manager.dart';
import 'crypto_service.dart';

// Classe responsável por gerenciar toda a comunicação com a API do NanoUrls
class ApiService {
  static const String _baseUrl = 'https://api.nanourls.com';
  final SessionManager _sessionManager = SessionManager();
  final CryptoService _cryptoService = CryptoService();
  static String? _cachedIp;

  // Monta os cabeçalhos padrão para as requisições HTTP, injetando o token de autorização quando necessário
  Map<String, String> _buildHeaders({bool requiresAuth = false}) {
    final headers = {
      'accept': '*/*',
      'Content-Type': 'application/json',
      'Accept-Language': _getLocaleHeader(),
    };

    if (requiresAuth) {
      final token = _sessionManager.token;
      if (token == null) {
        throw const HttpException('Não autorizado. Token de sessão não encontrado.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Centraliza o tratamento das respostas da API, evitando repetição de try/catch em cada método.
  // clearSessionOn401: alguns endpoints (criar/editar NanoUrl) reaproveitam o status 401 também
  // para rejeições de negócio (ex.: URL sinalizada pelo Safe Browsing), não só para token
  // inválido/expirado — nesses casos o chamador desliga a limpeza de sessão para não deslogar
  // o usuário por causa de uma URL recusada.
  dynamic _handleResponse(http.Response response, {List<int> validStatus = const [200, 201, 204], bool clearSessionOn401 = true}) {
    if (validStatus.contains(response.statusCode)) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    if (response.statusCode == 401 && clearSessionOn401) {
      _sessionManager.clearSession();
    }

    throw HttpException(_parseError(response));
  }

  // Coleta dados específicos do dispositivo, IP e o Token Push (FCM) para envio no momento do login e cadastro
  Future<Map<String, dynamic>> _buildDeviceAndFcmPayload() async {
    final ipAddress = await _getClientIp();
    final encryptedIp = ipAddress.contains(':') ? 'Unknow' : _cryptoService.encryptIpAddress(ipAddress);

    String deviceId = 'Unknown';
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'Unknown';
      }
    } catch (e) {
      debugPrint('Falha ao obter DeviceID: $e');
    }

    String? fcmToken;
    try {
      // Solicita permissão e aguarda a geração do token Push
      await FirebaseMessaging.instance.requestPermission();
      fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM Token gerado com sucesso: $fcmToken');
    } catch (e) {
      // Agora os erros não são mais silenciosos. Isso ajudará a debugar falhas em dispositivos reais.
      debugPrint('Falha crítica ao obter FCM Token: $e');
    }

    final platform = Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Unknown';

    return {
      'ipAddress': encryptedIp,
      'userAgent': platform,
      'referer': 'mobile-app',
      'deviceId': _cryptoService.encryptDeviceId(deviceId),
      'tokenFcm': fcmToken, // Enviado puro, sem criptografia, para evitar quebra de limite de string
    };
  }

  // Realiza o login do usuário, enviando dados do aparelho e o token de notificação
  Future<User> signIn(String credential, String password) async {
    final url = Uri.parse('$_baseUrl/v1/user/signin');

    // Coleta o payload base e injeta as credenciais criptografadas
    final payload = await _buildDeviceAndFcmPayload();
    payload['credential'] = _cryptoService.encryptEmail(credential.trim().toLowerCase());
    payload['password'] = _cryptoService.encryptPassword(password);

    try {
      final response = await http.post(
        url,
        headers: _buildHeaders(requiresAuth: false),
        body: jsonEncode(payload),
      );

      final responseBody = _handleResponse(response);
      if (responseBody == null) throw const HttpException('Resposta de autenticação vazia.');

      final token = responseBody['token'] as String;
      final user = User.fromJson(responseBody['user']);

      _sessionManager.saveSession(token, user);
      return user;
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique suas conexões.');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Falha na comunicação: $e');
    }
  }

  // Busca os provedores de identidade (SSO social) ativos no Keycloak, para montar
  // dinamicamente os botões sociais da tela de login. Indisponibilidade da API/Keycloak
  // não deve travar o login tradicional, então qualquer falha vira lista vazia
  Future<List<IdentityProviderDto>> fetchIdentityProviders() async {
    final url = Uri.parse('$_baseUrl/v1/user/identity-providers');
    try {
      final response = await http.get(url, headers: _buildHeaders());
      final List<dynamic> listJson = _handleResponse(response) ?? [];
      return listJson.map((item) => IdentityProviderDto.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  // Registra um novo usuário no sistema
  Future<void> signUp(String name, String email, String password) async {
    final url = Uri.parse('$_baseUrl/v1/user/signup');

    // Reaproveita a função de device/FCM para garantir consistência no token gerado e na criptografia do deviceId
    final devicePayload = await _buildDeviceAndFcmPayload();

    final body = {
      'userId': '',
      'userName': name.trim(),
      'email': _cryptoService.encryptEmail(email.trim().toLowerCase()),
      'password': _cryptoService.encryptPassword(password.trim()),
      'planId': 1,
      'enabled': true,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'lastModified': DateTime.now().toUtc().toIso8601String(),
      // Adicionando os novos campos no payload de registro
      'ipAddress': devicePayload['ipAddress'],
      'deviceId': devicePayload['deviceId'],
      'tokenFcm': devicePayload['tokenFcm'],
    };

    try {
      final response = await http.post(url, headers: _buildHeaders(), body: jsonEncode(body));
      _handleResponse(response, validStatus: [200, 201]);
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique suas conexões.');
    }
  }

  // Solicita a redefinição de senha para o e-mail informado
  Future<void> requestPasswordReset(String email) async {
    final url = Uri.parse('$_baseUrl/v1/forgot-pass/request-change/${Uri.encodeComponent(email.trim().toLowerCase())}');
    try {
      final response = await http.get(url, headers: _buildHeaders());
      _handleResponse(response);
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique suas conexões.');
    }
  }

  // Busca as métricas de acesso de uma URL encurtada
  Future<DashboardDataDto> fetchUrlAnalytics(String shortCode, {int days = 7}) async {
    final url = Uri.parse('$_baseUrl/v1/analytics/dashboard/$shortCode/$days');
    try {
      final response = await http.get(url, headers: _buildHeaders(requiresAuth: true));
      final data = _handleResponse(response);
      return DashboardDataDto.fromJson(data);
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Busca o dashboard comparativo (Analytics Hub) de todas as NanoUrls com analytics do usuário.
  // Sem "codes" o backend seleciona as mais clicadas (até MyAnalyticsDto.maxComparisonUrls).
  Future<MyAnalyticsDto> fetchMyAnalytics({int days = 7, List<String>? codes}) async {
    var path = '$_baseUrl/v1/analytics/my-dashboard/$days';
    if (codes != null && codes.isNotEmpty) {
      path += '?codes=${Uri.encodeQueryComponent(codes.join(','))}';
    }
    final url = Uri.parse(path);
    try {
      final response = await http.get(url, headers: _buildHeaders(requiresAuth: true));
      final data = _handleResponse(response);
      return MyAnalyticsDto.fromJson(data);
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Retorna a lista de URLs encurtadas pertencentes ao usuário logado
  Future<List<NanoUrl>> fetchUserUrls() async {
    final url = Uri.parse('$_baseUrl/v1/user/urls');
    try {
      final response = await http.get(url, headers: _buildHeaders(requiresAuth: true));
      final List<dynamic> listJson = _handleResponse(response);
      return listJson.map((item) => NanoUrl.fromJson(item)).toList();
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Verifica no servidor se um apelido (alias) customizado está disponível para uso
  Future<bool> checkAlias(String alias) async {
    if (alias.trim().isEmpty) return true;
    final url = Uri.parse('$_baseUrl/v1/nano/check-shorturl/$alias');
    try {
      final response = await http.get(url, headers: _buildHeaders());
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['isAvailable'] ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Salva uma nova URL encurtada na base
  Future<void> saveNanoUrl({
    required String shortUrl,
    required String realUrl,
    String? description,
    String? glyph,
    String? password,
    DateTime? expiresAt,
    required bool analytics,
  }) async {
    final url = Uri.parse('$_baseUrl/v1/user/save-nano');
    final body = {
      'shortUrl': shortUrl,
      'realUrl': realUrl,
      'description': description ?? '',
      'glyph': glyph ?? 'link',
      'password': password,
      'expriresAt': expiresAt?.toUtc().toIso8601String(),
      'analytics': analytics,
      'enabled': true,
    };

    try {
      final response = await http.put(url, headers: _buildHeaders(requiresAuth: true), body: jsonEncode(body));
      // 401 aqui pode ser o backend recusando a URL de destino (Safe Browsing), não a sessão
      _handleResponse(response, clearSessionOn401: false);
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Atualiza as configurações de uma URL encurtada existente
  Future<void> updateNanoUrl({
    required String shortUrl,
    required String realUrl,
    String? description,
    String? glyph,
    String? password,
    DateTime? expiresAt,
    required bool analytics,
    required bool enabled,
  }) async {
    final url = Uri.parse('$_baseUrl/v1/user/update-nano');
    final body = {
      'shortUrl': shortUrl,
      'realUrl': realUrl,
      'description': description ?? '',
      'glyph': glyph ?? 'link',
      'password': password,
      'expriresAt': expiresAt?.toUtc().toIso8601String(),
      'analytics': analytics,
      'enabled': enabled,
    };

    try {
      final response = await http.put(url, headers: _buildHeaders(requiresAuth: true), body: jsonEncode(body));
      // 401 aqui pode ser o backend recusando a URL de destino (Safe Browsing), não a sessão
      _handleResponse(response, clearSessionOn401: false);
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Envia uma URL para a lixeira (desativação lógica)
  Future<void> deleteNanoUrl(String shortUrl) async {
    final url = Uri.parse('$_baseUrl/v1/user/delete-nano');
    final body = {
      'shortUrl': shortUrl,
      'description': '',
      'realUrl': '',
      'glyph': 'link',
      'password': '',
      'expriresAt': null,
      'analytics': false,
      'enabled': false,
    };

    try {
      final response = await http.put(url, headers: _buildHeaders(requiresAuth: true), body: jsonEncode(body));
      _handleResponse(response, validStatus: [200, 201]);
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Consulta a quantidade de análises disponíveis para o plano atual do usuário
  Future<int> fetchAnalyticsLeft() async {
    final url = Uri.parse('$_baseUrl/v1/user/analytics-left');
    try {
      final response = await http.get(url, headers: _buildHeaders(requiresAuth: true));
      return _handleResponse(response) as int;
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Consulta o limite de URLs que o usuário ainda pode criar
  Future<int> fetchNanoUrlsLeft() async {
    final url = Uri.parse('$_baseUrl/v1/user/nanourls-left');
    try {
      final response = await http.get(url, headers: _buildHeaders(requiresAuth: true));
      return _handleResponse(response) as int;
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Obtém os detalhes completos do usuário logado
  Future<User> fetchCurrentUser() async {
    final url = Uri.parse('$_baseUrl/v1/user/get-by-id');
    try {
      final response = await http.get(url, headers: _buildHeaders(requiresAuth: true));
      final data = _handleResponse(response);
      return User.fromJson(data);
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Obtém as informações descritivas do plano de assinatura pelo ID
  Future<Plan> fetchPlanById(String planId) async {
    final url = Uri.parse('$_baseUrl/v1/plan/get-by-id/$planId');
    try {
      final response = await http.get(url, headers: _buildHeaders(requiresAuth: true));
      final data = _handleResponse(response);
      return Plan.fromJson(data);
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Obtém todos os planos ativos cadastrados
  Future<List<Plan>> fetchActivePlans() async {
    final url = Uri.parse('$_baseUrl/v1/plan/get-active');
    try {
      final response = await http.get(url, headers: _buildHeaders(requiresAuth: true));
      final List<dynamic> listJson = _handleResponse(response);
      return listJson.map((item) => Plan.fromJson(item)).toList();
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Altera o plano ativo do usuário
  Future<User> changePlan(String planId) async {
    final url = Uri.parse('$_baseUrl/v1/user/change-plan/$planId');
    try {
      final response = await http.put(url, headers: _buildHeaders(requiresAuth: true));
      final data = _handleResponse(response);

      final newToken = data['token'] as String;
      final updatedUser = User.fromJson(data['user']);

      _sessionManager.saveSession(newToken, updatedUser);
      return updatedUser;
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Atualiza as informações pessoais do usuário (nome ou e-mail)
  Future<User> updatePersonalData({String? userName, String? email}) async {
    final url = Uri.parse('$_baseUrl/v1/user/personal-data');
    final Map<String, dynamic> body = {};

    if (userName != null) body['userName'] = userName;
    if (email != null) body['email'] = _cryptoService.encryptEmail(email);

    try {
      final response = await http.put(url, headers: _buildHeaders(requiresAuth: true), body: jsonEncode(body));
      final data = _handleResponse(response);

      final newToken = data['token'] as String;
      final updatedUser = User.fromJson(data['user']);

      _sessionManager.saveSession(newToken, updatedUser);
      return updatedUser;
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Atualiza a senha do usuário
  Future<User> changePassword(String newPassword) async {
    final url = Uri.parse('$_baseUrl/v1/user/personal-data');
    final body = {'password': _cryptoService.encryptPassword(newPassword)};

    try {
      final response = await http.put(url, headers: _buildHeaders(requiresAuth: true), body: jsonEncode(body));
      final data = _handleResponse(response);

      final newToken = data['token'] as String;
      final updatedUser = User.fromJson(data['user']);

      _sessionManager.saveSession(newToken, updatedUser);
      return updatedUser;
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Apaga a conta do usuário permanentemente do sistema
  Future<void> deleteAccount() async {
    final url = Uri.parse('$_baseUrl/v1/user/delete-account');
    try {
      final response = await http.put(url, headers: _buildHeaders(requiresAuth: true));
      _handleResponse(response, validStatus: [200, 204]);
      _sessionManager.clearSession();
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    }
  }

  // Efetua logout na API passando o deviceId criptografado no body
  Future<void> logout() async {
    final url = Uri.parse('$_baseUrl/v1/user/log-out');
    final payload = await _buildDeviceAndFcmPayload();
    final device = Device(
      deviceId: payload['deviceId'] as String,
      userId: '',
      tokenFcm: '',
    );

    try {
      final response = await http.delete(
        url,
        headers: _buildHeaders(requiresAuth: true),
        body: jsonEncode(device.toJson()),
      );
      _handleResponse(response, validStatus: [200, 204]);
    } on SocketException {
      // Ignora erro de rede no logout para prosseguir com a limpeza local
    } catch (_) {
      // Ignora outros erros no logout para prosseguir com a limpeza local
    }
  }

  // Extrai o IP público da conexão atual e armazena em cache
  Future<String> _getClientIp() async {
    if (_cachedIp != null) return _cachedIp!;
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        _cachedIp = response.body.trim();
        return _cachedIp!;
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  // Identifica o idioma padrão do aparelho para envio aos servidores (ex: pt-BR)
  String _getLocaleHeader() {
    try {
      final String fullLocale = Platform.localeName.replaceAll('_', '-');
      if (fullLocale.startsWith('pt')) return 'pt-BR';
      if (fullLocale.startsWith('es')) return 'es';
      if (fullLocale.startsWith('fr')) return 'fr';
      return 'en';
    } catch (_) {
      return 'en';
    }
  }

  // Tenta extrair uma mensagem de erro compreensível do retorno do servidor.
  // Alguns endpoints (ex.: rejeição do Safe Browsing em save-nano/update-nano) devolvem o corpo
  // como texto puro em vez do formato usual {"message": "..."}, então o parser cobre os dois casos.
  String _parseError(http.Response response, {String defaultMsg = 'Erro no servidor'}) {
    final rawBody = response.body.trim();
    if (rawBody.isEmpty) return '$defaultMsg (Status: ${response.statusCode})';

    try {
      final data = jsonDecode(rawBody);

      if (data is String && data.isNotEmpty) return data;

      if (data is Map) {
        final messageObj = data['message'];
        if (messageObj is String && messageObj.isNotEmpty) return messageObj;
        if (messageObj is Map) {
          if (messageObj['value'] is String) return messageObj['value'];
          if (messageObj['name'] is String) return messageObj['name'];
        }
      }
    } catch (_) {
      // Corpo não é JSON válido — trata como texto puro vindo direto do servidor.
      // Limite de tamanho evita refletir uma página de erro HTML/stack trace na tela do usuário.
      if (rawBody.length < 300) return rawBody;
    }

    return '$defaultMsg (Status: ${response.statusCode})';
  }
}