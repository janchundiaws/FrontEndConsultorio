import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:odontologo/variables_globales.dart';

class AuthService {
  static const String _tokenKey = 'token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _fechaValidaTokenKey = 'fechaValidaToken';
  static const String _tenantIdKey = 'tenantId';
  static const String _tokenExpirationKey = 'token_expiration';

  // Verificar si el usuario está autenticado
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final expiration = prefs.getString(_tokenExpirationKey);
    
    if (token == null || token.isEmpty) return false;
    
    // Verificar si el token no ha expirado
    if (expiration != null && expiration.isNotEmpty) {
      final expirationDate = DateTime.tryParse(expiration);
      if (expirationDate != null && DateTime.now().isBefore(expirationDate)) {
        return true;
      }
    }
    
    // Si el token expiró, intentar renovarlo
    return await _refreshTokenIfNeeded();
  }

  // Renovar token si es necesario
  static Future<bool> _refreshTokenIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      
      if (refreshToken == null || refreshToken.isEmpty) return false;
      
      final result = await refreshTokenRequest(refreshToken);
      if (result['success']) {
        await _saveTokenData(result['token'], result['refresh_token'], result['expiration']);
        return true;
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
    
    return false;
  }

  // Obtener token almacenado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Login del usuario
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/api/login'));
      request.body = json.encode({
        "correo": username,
        "password": password
      });
      request.headers.addAll(_getHeaders());

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(responseBody);
        
        // Guardar tokens automáticamente
        await _saveTokenData(
          jsonData['token'],
          jsonData['refresh_token'] ?? '',
          jsonData['expiration'] ?? _calculateExpiration(),
        );
        
        return {
          'success': true,
          'token': jsonData['token'],
          'refresh_token': jsonData['refresh_token'],
          'expiration': jsonData['expiration'],
          'message': 'Login exitoso'
        };
      } else {
        return {
          'success': false,
          'message': 'Credenciales inválidas',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  // Solicitar refresh token
  static Future<Map<String, dynamic>> refreshTokenRequest(String refreshToken) async {
    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/api/refresh-token'));
      request.body = json.encode({
        "refresh_token": refreshToken
      });
      request.headers.addAll(_getHeaders());

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(responseBody);
        return {
          'success': true,
          'token': jsonData['token'],
          'refresh_token': jsonData['refresh_token'],
          'expiration': jsonData['expiration'],
        };
      } else {
        return {
          'success': false,
          'message': 'Token de renovación inválido',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  // Guardar datos del token
  static Future<void> _saveTokenData(String token, String refreshToken, String expiration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_tokenExpirationKey, expiration);
  }

  // Calcular fecha de expiración (24 horas por defecto)
  static String _calculateExpiration() {
    final expiration = DateTime.now().add(const Duration(hours: 24));
    return expiration.toIso8601String();
  }

  // Guardar credenciales
  static Future<void> saveCredentials({
    required String username,
    required String password,
    required String token,
    required String fechaValidaToken,
    required String tenantId,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (rememberMe) {
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_passwordKey, password);
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_fechaValidaTokenKey, fechaValidaToken);
      await prefs.setString(_tenantIdKey, tenantId);
    } else {
      await prefs.remove(_usernameKey);
      await prefs.remove(_passwordKey);
      await prefs.remove(_tokenKey);
      await prefs.remove(_fechaValidaTokenKey);
      await prefs.remove(_tenantIdKey);
    }
  }

  // Cargar credenciales guardadas
  static Future<Map<String, String>> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_usernameKey) ?? '',
      'password': prefs.getString(_passwordKey) ?? '',
      'token': prefs.getString(_tokenKey) ?? '',
      'fechaValidaToken': prefs.getString(_fechaValidaTokenKey) ?? '',
      'tenantId': prefs.getString(_tenantIdKey) ?? '',
    };
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpirationKey);
    await prefs.remove(_fechaValidaTokenKey);
    await prefs.remove(_tenantIdKey);
  }

  // Verificar token con el servidor
  static Future<bool> verifyToken() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return false;

      final request = http.Request('GET', Uri.parse('$baseUrl/api/verify-token'));
      request.headers.addAll(_getHeaders());
      request.headers['Authorization'] = 'Bearer $token';

      final response = await request.send();
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  // Headers para las peticiones
  static Map<String, String> _getHeaders() {
    return {
      'Accept': '*/*',
      'x-tenant-id': 'Admin',
      'Content-Type': 'application/json',
      //'Access-Control-Allow-Origin': '*',
    };
  }

  // Headers con token para peticiones autenticadas
  static Future<Map<String, String>> getAuthenticatedHeaders() async {
    final token = await getToken();
    final headers = _getHeaders();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
} 