import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:odontologo/services/auth_service.dart';
import 'package:odontologo/variables_globales.dart';

class HttpService {
  static const Duration _timeout = Duration(seconds: 30);

  // GET request
  static Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = await _buildHeaders(headers);
      
      final response = await http.get(url, headers: requestHeaders)
          .timeout(_timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw HttpException('Error en GET request: $e');
    }
  }

  // POST request
  static Future<http.Response> post(String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = await _buildHeaders(headers);
      
      final response = await http.post(
        url,
        headers: requestHeaders,
        body: body is String ? body : jsonEncode(body),
      ).timeout(_timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw HttpException('Error en POST request: $e');
    }
  }

  // PUT request
  static Future<http.Response> put(String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = await _buildHeaders(headers);
      
      final response = await http.put(
        url,
        headers: requestHeaders,
        body: body is String ? body : jsonEncode(body),
      ).timeout(_timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw HttpException('Error en PUT request: $e');
    }
  }

  // DELETE request
  static Future<http.Response> delete(String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = await _buildHeaders(headers);
      
      final response = await http.delete(
        url,
        headers: requestHeaders,
        body: body is String ? body : jsonEncode(body),
      ).timeout(_timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw HttpException('Error en DELETE request: $e');
    }
  }

  // Construir headers con manejo de CORS
  static Future<Map<String, String>> _buildHeaders(Map<String, String>? customHeaders) async {
    final baseHeaders = {
      'Accept': '*/*',
      'x-tenant-id': 'Admin',
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
    };

    // Agregar token si está disponible
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      baseHeaders['Authorization'] = 'Bearer $token';
    }

    // Agregar headers personalizados
    if (customHeaders != null) {
      baseHeaders.addAll(customHeaders);
    }

    return baseHeaders;
  }

  // Manejar respuesta y errores
  static http.Response _handleResponse(http.Response response) {
    // Manejar errores de CORS
    if (response.statusCode == 403) {
      throw HttpException('Error de CORS: Acceso denegado');
    }

    // Manejar errores de autenticación
    if (response.statusCode == 401) {
      throw HttpException('Token inválido o expirado');
    }

    // Manejar errores del servidor
    if (response.statusCode >= 500) {
      throw HttpException('Error del servidor: ${response.statusCode}');
    }

    // Manejar errores de cliente
    if (response.statusCode >= 400 && response.statusCode < 500) {
      throw HttpException('Error de cliente: ${response.statusCode}');
    }

    return response;
  }

  // Verificar conectividad
  static Future<bool> checkConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Accept': '*/*'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
} 