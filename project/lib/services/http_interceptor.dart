import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:odontologo/services/auth_service.dart';
import 'package:odontologo/services/http_service.dart';
import 'package:odontologo/variables_globales.dart';

class HttpInterceptor {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Cola de peticiones pendientes durante renovación de token
  static final List<_PendingRequest> _pendingRequests = [];
  static bool _isRefreshingToken = false;

  // Interceptar peticiones HTTP
  static Future<http.Response> intercept(Future<http.Response> Function() request) async {
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        final response = await request();
        
        // Si la respuesta es exitosa, procesar peticiones pendientes
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _processPendingRequests();
          return response;
        }
        
        // Si es error 401, intentar renovar token
        if (response.statusCode == 401) {
          final refreshed = await _handleTokenRefresh();
          if (refreshed) {
            retryCount++;
            continue; // Reintentar la petición
          } else {
            // Si no se pudo renovar, limpiar tokens y redirigir al login
            await AuthService.logout();
            throw HttpException('Sesión expirada. Por favor, inicie sesión nuevamente.');
          }
        }
        
        // Para otros errores, verificar si debemos reintentar
        if (_shouldRetry(response.statusCode) && retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(retryDelay * retryCount);
          continue;
        }
        
        return response;
        
      } catch (e) {
        retryCount++;
        
        if (retryCount >= maxRetries) {
          throw HttpException('Error después de $maxRetries intentos: $e');
        }
        
        // Esperar antes del siguiente intento
        await Future.delayed(retryDelay * retryCount);
      }
    }
    
    throw HttpException('Error después de $maxRetries intentos');
  }

  // Manejar renovación de token
  static Future<bool> _handleTokenRefresh() async {
    if (_isRefreshingToken) {
      // Si ya se está renovando, agregar a la cola de espera
      return await _waitForTokenRefresh();
    }

    _isRefreshingToken = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final result = await AuthService.refreshTokenRequest(refreshToken);
      
      if (result['success']) {
        // Procesar peticiones pendientes con el nuevo token
        _processPendingRequests();
        return true;
      }
      
      return false;
    } catch (e) {
      //print('Error refreshing token: $e');
      return false;
    } finally {
      _isRefreshingToken = false;
    }
  }

  // Esperar a que se complete la renovación del token
  static Future<bool> _waitForTokenRefresh() async {
    final completer = Completer<bool>();
    _pendingRequests.add(_PendingRequest(completer));
    return await completer.future;
  }

  // Procesar peticiones pendientes
  static void _processPendingRequests() {
    for (final pendingRequest in _pendingRequests) {
      pendingRequest.completer.complete(true);
    }
    _pendingRequests.clear();
  }

  // Determinar si se debe reintentar basado en el código de estado
  static bool _shouldRetry(int statusCode) {
    // Reintentar en errores del servidor (5xx) y algunos errores de cliente (4xx)
    return statusCode >= 500 || 
           statusCode == 408 || // Request Timeout
           statusCode == 429;   // Too Many Requests
  }

  // Interceptar peticiones GET
  static Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    return await intercept(() async {
      final url = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = await _buildHeaders(headers);
      //print('requestHeaders $requestHeaders');
      //print('url $url');
      return await http.get(url, headers: requestHeaders);
    });
  }

  // Interceptar peticiones POST
  static Future<http.Response> post(String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return await intercept(() async {
      final url = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = await _buildHeaders(headers);

      return await http.post(
        url,
        headers: requestHeaders,
        body: body is String ? body : jsonEncode(body),
      );
    });
  }

  // Interceptar peticiones PUT
  static Future<http.Response> put(String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return await intercept(() async {
      final url = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = await _buildHeaders(headers);
      return await http.put(
        url,
        headers: requestHeaders,
        body: body is String ? body : jsonEncode(body),
      );
    });
  }

  // Interceptar peticiones DELETE
  static Future<http.Response> delete(String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return await intercept(() async {
      final url = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = await _buildHeaders(headers);
      return await http.delete(
        url,
        headers: requestHeaders,
        body: body is String ? body : jsonEncode(body),
      );
    });
  }

  // Construir headers con token actualizado
  static Future<Map<String, String>> _buildHeaders(Map<String, String>? customHeaders) async {
    final baseHeaders = {
      'Accept': '*/*',
      'x-tenant-id': 'Admin',
      'Content-Type': 'application/json',
    };

    // Agregar token actualizado
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
}

// Clase para manejar peticiones pendientes
class _PendingRequest {
  final Completer<bool> completer;
  
  _PendingRequest(this.completer);
}

// Clase para manejar errores de red
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;
  
  NetworkException(this.message, {this.statusCode, this.endpoint});
  
  @override
  String toString() => 'NetworkException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
} 