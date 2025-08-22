import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

class LoggerService {
  static const String _logPrefix = 'app_logs_';
  static const int _maxLogEntries = 1000;
  static const Duration _logRetention = Duration(days: 7);
  
  static LogLevel _currentLevel = LogLevel.info;
  static bool _enableConsoleLogging = true;
  static bool _enableFileLogging = true;

  // Configurar nivel de logging
  static void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }

  // Configurar logging
  static void configure({
    LogLevel level = LogLevel.info,
    bool enableConsole = true,
    bool enableFile = true,
  }) {
    _currentLevel = level;
    _enableConsoleLogging = enableConsole;
    _enableFileLogging = enableFile;
  }

  // Log de debug
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  // Log de información
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  // Log de advertencia
  static void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  // Log de error
  static void error(String message, {String? tag, Map<String, dynamic>? data, Object? error}) {
    _log(LogLevel.error, message, tag: tag, data: data, error: error);
  }

  // Log fatal
  static void fatal(String message, {String? tag, Map<String, dynamic>? data, Object? error}) {
    _log(LogLevel.fatal, message, tag: tag, data: data, error: error);
  }

  // Método principal de logging
  static void _log(LogLevel level, String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
  }) async {
    // Verificar nivel de logging
    if (level.index < _currentLevel.index) {
      return;
    }

    final timestamp = DateTime.now();
    final logEntry = {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name.toUpperCase(),
      'message': message,
      'tag': tag ?? 'APP',
      'data': data,
      'error': error?.toString(),
      'stackTrace': error is Error ? error.stackTrace?.toString() : null,
    };

    // Log a consola
    if (_enableConsoleLogging) {
      _logToConsole(logEntry);
    }

    // Log a archivo
    if (_enableFileLogging) {
      await _logToFile(logEntry);
    }
  }

  // Log a consola
  static void _logToConsole(Map<String, dynamic> logEntry) {
    final level = logEntry['level'];
    final tag = logEntry['tag'];
    final message = logEntry['message'];
    final data = logEntry['data'];
    final error = logEntry['error'];

    String consoleMessage = '[$level] [$tag] $message';
    
    if (data != null) {
      consoleMessage += ' | Data: ${jsonEncode(data)}';
    }
    
    if (error != null) {
      consoleMessage += ' | Error: $error';
    }

    switch (level) {
      case 'DEBUG':
        developer.log(consoleMessage, name: tag);
        break;
      case 'INFO':
        developer.log(consoleMessage, name: tag);
        break;
      case 'WARNING':
        developer.log(consoleMessage, name: tag, level: 900);
        break;
      case 'ERROR':
      case 'FATAL':
        developer.log(consoleMessage, name: tag, level: 1000, error: error);
        break;
    }
  }

  // Log a archivo
  static Future<void> _logToFile(Map<String, dynamic> logEntry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logKey = _getLogKey(DateTime.now());
      
      // Obtener logs existentes
      final existingLogsJson = prefs.getString(logKey) ?? '[]';
      final existingLogs = List<Map<String, dynamic>>.from(
        jsonDecode(existingLogsJson),
      );
      
      // Agregar nuevo log
      existingLogs.add(logEntry);
      
      // Limitar número de entradas
      if (existingLogs.length > _maxLogEntries) {
        existingLogs.removeRange(0, existingLogs.length - _maxLogEntries);
      }
      
      // Guardar logs
      await prefs.setString(logKey, jsonEncode(existingLogs));
      
      // Limpiar logs antiguos
      await _cleanupOldLogs();
      
    } catch (e) {
      // Si falla el logging a archivo, solo log a consola
      if (kDebugMode) {
        print('Error saving log to file: $e');
      }
    }
  }

  // Obtener logs
  static Future<List<Map<String, dynamic>>> getLogs({
    DateTime? from,
    DateTime? to,
    LogLevel? level,
    String? tag,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final allLogs = <Map<String, dynamic>>[];
      
      for (final key in keys) {
        if (key.startsWith(_logPrefix)) {
          final logsJson = prefs.getString(key);
          if (logsJson != null) {
            final logs = List<Map<String, dynamic>>.from(jsonDecode(logsJson));
            allLogs.addAll(logs);
          }
        }
      }
      
      // Filtrar logs
      return allLogs.where((log) {
        final timestamp = DateTime.parse(log['timestamp']);
        
        // Filtro por fecha
        if (from != null && timestamp.isBefore(from)) return false;
        if (to != null && timestamp.isAfter(to)) return false;
        
        // Filtro por nivel
        if (level != null) {
          final logLevel = LogLevel.values.firstWhere(
            (l) => l.name.toUpperCase() == log['level'],
            orElse: () => LogLevel.info,
          );
          if (logLevel.index < level.index) return false;
        }
        
        // Filtro por tag
        if (tag != null && log['tag'] != tag) return false;
        
        return true;
      }).toList();
      
    } catch (e) {
      return [];
    }
  }

  // Obtener logs recientes
  static Future<List<Map<String, dynamic>>> getRecentLogs({
    int limit = 100,
    LogLevel? level,
    String? tag,
  }) async {
    final logs = await getLogs(level: level, tag: tag);
    logs.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
    return logs.take(limit).toList();
  }

  // Limpiar logs
  static Future<void> clearLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_logPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      error('Error clearing logs: $e');
    }
  }

  // Exportar logs
  static Future<String> exportLogs({
    DateTime? from,
    DateTime? to,
    LogLevel? level,
    String? tag,
  }) async {
    final logs = await getLogs(from: from, to: to, level: level, tag: tag);
    return jsonEncode(logs);
  }

  // Obtener estadísticas de logs
  static Future<Map<String, dynamic>> getLogStats() async {
    try {
      final logs = await getLogs();
      final stats = <String, int>{};
      
      for (final log in logs) {
        final level = log['level'];
        stats[level] = (stats[level] ?? 0) + 1;
      }
      
      return {
        'totalLogs': logs.length,
        'byLevel': stats,
        'oldestLog': logs.isNotEmpty ? logs.first['timestamp'] : null,
        'newestLog': logs.isNotEmpty ? logs.last['timestamp'] : null,
      };
    } catch (e) {
      return {
        'totalLogs': 0,
        'byLevel': {},
        'error': e.toString(),
      };
    }
  }

  // Limpiar logs antiguos
  static Future<void> _cleanupOldLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cutoffDate = DateTime.now().subtract(_logRetention);
      
      for (final key in keys) {
        if (key.startsWith(_logPrefix)) {
          final logsJson = prefs.getString(key);
          if (logsJson != null) {
            final logs = List<Map<String, dynamic>>.from(jsonDecode(logsJson));
            
            // Filtrar logs antiguos
            final recentLogs = logs.where((log) {
              final timestamp = DateTime.parse(log['timestamp']);
              return timestamp.isAfter(cutoffDate);
            }).toList();
            
            if (recentLogs.isEmpty) {
              // Si no hay logs recientes, eliminar la clave
              await prefs.remove(key);
            } else if (recentLogs.length != logs.length) {
              // Si se eliminaron logs, actualizar
              await prefs.setString(key, jsonEncode(recentLogs));
            }
          }
        }
      }
    } catch (e) {
      // Silenciar errores de limpieza
    }
  }

  // Generar clave de log
  static String _getLogKey(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$_logPrefix$dateStr';
  }

  // Log de performance
  static void logPerformance(String operation, Duration duration, {String? tag}) {
    info(
      'Performance: $operation took ${duration.inMilliseconds}ms',
      tag: tag ?? 'PERFORMANCE',
      data: {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        'duration_microseconds': duration.inMicroseconds,
      },
    );
  }

  // Log de API calls
  static void logApiCall(String endpoint, String method, int statusCode, Duration duration, {String? tag}) {
    final level = statusCode >= 400 ? LogLevel.error : LogLevel.info;
    _log(
      level,
      'API Call: $method $endpoint - $statusCode',
      tag: tag ?? 'API',
      data: {
        'endpoint': endpoint,
        'method': method,
        'statusCode': statusCode,
        'duration_ms': duration.inMilliseconds,
      },
    );
  }

  // Log de errores de red
  static void logNetworkError(String endpoint, String method, String errorMessage, {String? tag}) {
    error(
      'Network Error: $method $endpoint',
      tag: tag ?? 'NETWORK',
      data: {
        'endpoint': endpoint,
        'method': method,
      },
      error: errorMessage,
    );
  }

  // Log de autenticación
  static void logAuth(String action, {String? userId, bool? success, String? error}) {
    final level = success == false ? LogLevel.error : LogLevel.info;
    _log(
      level,
      'Authentication: $action',
      tag: 'AUTH',
      data: {
        'action': action,
        'userId': userId,
        'success': success,
      },
      error: error,
    );
  }

  // Log de navegación
  static void logNavigation(String from, String to, {String? tag}) {
    info(
      'Navigation: $from -> $to',
      tag: tag ?? 'NAVIGATION',
      data: {
        'from': from,
        'to': to,
      },
    );
  }
} 