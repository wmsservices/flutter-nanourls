import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../entities/user.dart';
import '../entities/nano_url.dart';
import '../dtos/dashboard_data_dto.dart';
import 'session_manager.dart';
import 'crypto_service.dart';

// Service layer dealing with external API requests to NanoUrls backend
class ApiService {
  static const String _baseUrl = 'https://api.nanourls.com';
  final SessionManager _sessionManager = SessionManager();
  final CryptoService _cryptoService = CryptoService();

  // Helper to extract the device local locale string, formatting to language tags (e.g. pt-BR)
  String _getLocaleHeader() {
    try {
      final String fullLocale = Platform.localeName.replaceAll('_', '-');
      // Normalize to pt-BR, en, es, fr as supported by API
      if (fullLocale.startsWith('pt')) return 'pt-BR';
      if (fullLocale.startsWith('es')) return 'es';
      if (fullLocale.startsWith('fr')) return 'fr';
      return 'en';
    } catch (_) {
      return 'en'; // Default fallback
    }
  }

  // Fetches the client's public IPv4 address from ipify
  Future<String> _getClientIp() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (_) {
      // Fallback
    }
    return '127.0.0.1';
  }

  // Executes Sign-In POST request to /v1/user/signin with robust body and exception parsing
  Future<User> signIn(String credential, String password) async {
    final url = Uri.parse('$_baseUrl/v1/user/signin');
    final locale = _getLocaleHeader();

    final encryptedEmail = _cryptoService.encryptEmail(credential.trim().toLowerCase());
    final encryptedPassword = _cryptoService.encryptPassword(password);
    
    final ipAddress = await _getClientIp();
    final encryptedIp = ipAddress.contains(':') ? 'Unknow' : _cryptoService.encryptIpAddress(ipAddress);

    try {
      final platform = Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Unknown';
      final response = await http.post(
        url,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
          'Accept-Language': locale,
         },
        body: jsonEncode({
          'credential': encryptedEmail,
          'password': encryptedPassword,
          'ipAddress': encryptedIp,
          'userAgent': platform,
          'referer': 'mobile-app',
        }),
      );

      // Decode response body safely only if not empty
      Map<String, dynamic>? responseBody;
      if (response.body.isNotEmpty) {
        try {
          responseBody = jsonDecode(response.body);
        } catch (_) {
          // Body is not valid JSON
        }
      }

      // Check status codes
      if (response.statusCode == 200) {
        if (responseBody == null) {
          throw const HttpException('Resposta de autenticação vazia.');
        }
        final token = responseBody['token'] as String;
        final userJson = responseBody['user'] as Map<String, dynamic>;
        final user = User.fromJson(userJson);
        
        _sessionManager.saveSession(token, user);
        return user;
      } else if (response.statusCode == 401) {
        // Retrieve backend message or default to credentials error
        final errorMessage = responseBody?['message'] ?? 'Credenciais inválidas.';
        throw HttpException(errorMessage);
      } else {
        final errorMessage = responseBody?['message'] ?? 'Serviço temporariamente indisponível.';
        throw HttpException(errorMessage);
      }
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique suas conexões.');
    } on FormatException {
      throw const HttpException('Servidor retornou um formato de resposta inesperado.');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Falha na comunicação: ${e.toString()}');
    }
  }

  // Executes User Sign-Up POST request to /v1/user/signup
  Future<void> signUp(String name, String email, String password) async {
    final url = Uri.parse('$_baseUrl/v1/user/signup');
    final locale = _getLocaleHeader();

    final encryptedEmail = _cryptoService.encryptEmail(email.trim().toLowerCase());
    final encryptedPassword = _cryptoService.encryptPassword(password.trim());

    final body = {
      'userId': '',
      'userName': name.trim(),
      'email': encryptedEmail,
      'password': encryptedPassword,
      'planId': 1,
      'enabled': true,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'lastModified': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
          'Accept-Language': locale,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw HttpException(_parseError(response));
      }
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique suas conexões.');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de rede: ${e.toString()}');
    }
  }

  // Fetches analytical metrics GET request to /v1/analytics/dashboard/{shortCode}/{days}
  Future<DashboardDataDto> fetchUrlAnalytics(String shortCode, {int days = 7}) async {
    final token = _sessionManager.token;
    if (token == null) {
      throw const HttpException('Não autorizado. Token de sessão não encontrado.');
    }
    final url = Uri.parse('$_baseUrl/v1/analytics/dashboard/$shortCode/$days');
    final locale = _getLocaleHeader();
    try {
      final response = await http.get(
        url,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Accept-Language': locale,
        },
      );
      if (response.statusCode == 200) {
        return DashboardDataDto.fromJson(jsonDecode(response.body));
      } else {
        throw HttpException(_parseError(response));
      }
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de rede: ${e.toString()}');
    }
  }

  // Fetches user URLs GET request to /v1/user/urls
  Future<List<NanoUrl>> fetchUserUrls() async {
    final token = _sessionManager.token;
    if (token == null) {
      throw const HttpException('Não autorizado. Token de sessão não encontrado.');
    }

    final url = Uri.parse('$_baseUrl/v1/user/urls');
    final locale = _getLocaleHeader();

    try {
      final response = await http.get(
        url,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Accept-Language': locale,
        },
      );

      if (_isValidStatusCode(response.statusCode)) {
        final List<dynamic> listJson = jsonDecode(response.body);
        return listJson.map((item) => NanoUrl.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        _sessionManager.clearSession();
        throw const HttpException('Sessão expirada. Por favor, faça login novamente.');
      } else {
        throw const HttpException('Erro ao carregar seus links.');
      }
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    } on FormatException {
      throw const HttpException('Erro de formato na resposta dos links do servidor.');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de rede: ${e.toString()}');
    }
  }

  // Checks alias availability against the backend
  Future<bool> checkAlias(String alias) async {
    if (alias.trim().isEmpty) return true;
    final url = Uri.parse('$_baseUrl/v1/nano/check-shorturl/$alias');
    try {
      final response = await http.get(url, headers: {
        'accept': '*/*',
      });
      if (_isValidStatusCode(response.statusCode)) {
        final data = jsonDecode(response.body);
        return data['isAvailable'] ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Saves a new shortened URL
  Future<void> saveNanoUrl({
    required String shortUrl,
    required String realUrl,
    String? description,
    String? glyph,
    String? password,
    DateTime? expiresAt,
    required bool analytics,
  }) async {
    final token = _sessionManager.token;
    if (token == null) {
      throw const HttpException('Não autorizado. Token de sessão não encontrado.');
    }
    final url = Uri.parse('$_baseUrl/v1/user/save-nano');
    final locale = _getLocaleHeader();
    final body = {
      'shortUrl': shortUrl,
      'realUrl': realUrl,
      'description': description ?? '',
      'glyph': glyph ?? 'link',
      'password': password,
      'expriresAt': expiresAt?.toUtc().toIso8601String(), // C# class has 'ExpriresAt' property spelling
      'analytics': analytics,
      'enabled': true,
    };

    try {
      final response = await http.put(
        url,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept-Language': locale,
        },
        body: jsonEncode(body),
      );

      if (_isValidStatusCode(response.statusCode) == false) {
        final errorMsg = _parseError(response);
        throw HttpException(errorMsg);
      }
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de rede: ${e.toString()}');
    }
  }

  // Updates an existing shortened URL
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
    final token = _sessionManager.token;
    if (token == null) {
      throw const HttpException('Não autorizado. Token de sessão não encontrado.');
    }
    final url = Uri.parse('$_baseUrl/v1/user/update-nano');
    final locale = _getLocaleHeader();
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
      final response = await http.put(
        url,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept-Language': locale,
        },
        body: jsonEncode(body),
      );

      if (_isValidStatusCode(response.statusCode) == false) {
        final errorMsg = _parseError(response);
        throw HttpException(errorMsg);
      }
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de rede: ${e.toString()}');
    }
  }

  // Moves a shortened URL to the trash or deletes it
  Future<void> deleteNanoUrl(String shortUrl) async {
    final token = _sessionManager.token;
    if (token == null) {
      throw const HttpException('Não autorizado. Token de sessão não encontrado.');
    }
    final url = Uri.parse('$_baseUrl/v1/user/delete-nano');
    final locale = _getLocaleHeader();
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
      final response = await http.put(
        url,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept-Language': locale,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorMsg = _parseError(response);
        throw HttpException(errorMsg);
      }
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de rede: ${e.toString()}');
    }
  }

  // Fetches how many analytics are left for the user
  Future<int> fetchAnalyticsLeft() async {
    final token = _sessionManager.token;
    if (token == null) {
      throw const HttpException('Não autorizado. Token de sessão não encontrado.');
    }
    final url = Uri.parse('$_baseUrl/v1/user/analytics-left');
    final locale = _getLocaleHeader();
    try {
      final response = await http.get(
        url,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Accept-Language': locale,
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as int;
      } else {
        throw const HttpException('Erro ao carregar limite de analytics.');
      }
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de rede: ${e.toString()}');
    }
  }

  // Fetches how many nanourls are left for the user
  Future<int> fetchNanoUrlsLeft() async {
    final token = _sessionManager.token;
    if (token == null) {
      throw const HttpException('Não autorizado. Token de sessão não encontrado.');
    }
    final url = Uri.parse('$_baseUrl/v1/user/nanourls-left');
    final locale = _getLocaleHeader();
    try {
      final response = await http.get(
        url,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Accept-Language': locale,
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as int;
      } else {
        throw const HttpException('Erro ao carregar limite de NanoUrls.');
      }
    } on SocketException {
      throw const HttpException('Sem conexão com a internet. Verifique sua rede.');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de rede: ${e.toString()}');
    }
  }

  // Safe helper to extract error messages from HTTP responses
  String _parseError(http.Response response) {
    try {
      if (response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        return data['message'] ?? response.body;
      }
    } catch (_) {}
    return 'Erro no servidor (Status: ${response.statusCode})';
  }
  
  bool _isValidStatusCode(int code) {
    return code >= 200 && code < 300;
  }
}
