import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _cachePrefix = 'cache_';
  static const String _cacheMetadataPrefix = 'cache_metadata_';
  static const Duration _defaultExpiration = Duration(minutes: 30);
  static const int _maxCacheSize = 100; // Número máximo de elementos en caché

  // Guardar datos en caché
  static Future<void> set(String key, dynamic data, {Duration? expiration}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);
      final metadataKey = _getMetadataKey(key);
      
      final expirationTime = DateTime.now().add(expiration ?? _defaultExpiration);
      
      // Guardar datos
      final jsonData = jsonEncode(data);
      await prefs.setString(cacheKey, jsonData);
      
      // Guardar metadata (fecha de expiración)
      final metadata = {
        'expiration': expirationTime.toIso8601String(),
        'created': DateTime.now().toIso8601String(),
        'size': jsonData.length,
      };
      await prefs.setString(metadataKey, jsonEncode(metadata));
      
      // Limpiar caché si es necesario
      await _cleanupCache();
      
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  // Obtener datos del caché
  static Future<T?> get<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);
      final metadataKey = _getMetadataKey(key);
      
      // Verificar si existe
      if (!prefs.containsKey(cacheKey)) {
        return null;
      }
      
      // Verificar expiración
      final metadataJson = prefs.getString(metadataKey);
      if (metadataJson != null) {
        final metadata = jsonDecode(metadataJson);
        final expiration = DateTime.parse(metadata['expiration']);
        
        if (DateTime.now().isAfter(expiration)) {
          // Datos expirados, eliminarlos
          await remove(key);
          return null;
        }
      }
      
      // Obtener datos
      final jsonData = prefs.getString(cacheKey);
      if (jsonData != null) {
        return jsonDecode(jsonData) as T;
      }
      
    } catch (e) {
      print('Error getting from cache: $e');
    }
    
    return null;
  }

  // Verificar si existe en caché
  static Future<bool> exists(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);
      
      if (!prefs.containsKey(cacheKey)) {
        return false;
      }
      
      // Verificar expiración
      final metadataKey = _getMetadataKey(key);
      final metadataJson = prefs.getString(metadataKey);
      
      if (metadataJson != null) {
        final metadata = jsonDecode(metadataJson);
        final expiration = DateTime.parse(metadata['expiration']);
        
        if (DateTime.now().isAfter(expiration)) {
          await remove(key);
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Remover del caché
  static Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);
      final metadataKey = _getMetadataKey(key);
      
      await prefs.remove(cacheKey);
      await prefs.remove(metadataKey);
    } catch (e) {
      print('Error removing from cache: $e');
    }
  }

  // Limpiar todo el caché
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheMetadataPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Obtener estadísticas del caché
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int totalItems = 0;
      int expiredItems = 0;
      int totalSize = 0;
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          totalItems++;
          
          //final dataKey = key;
          final metadataKey = _getMetadataKey(key.replaceFirst(_cachePrefix, ''));
          
          if (prefs.containsKey(metadataKey)) {
            final metadataJson = prefs.getString(metadataKey);
            if (metadataJson != null) {
              final metadata = jsonDecode(metadataJson);
              totalSize += int.parse(metadata['size'] ?? 0);
              
              final expiration = DateTime.parse(metadata['expiration']);
              if (DateTime.now().isAfter(expiration)) {
                expiredItems++;
              }
            }
          }
        }
      }
      
      return {
        'totalItems': totalItems,
        'expiredItems': expiredItems,
        'validItems': totalItems - expiredItems,
        'totalSize': totalSize,
        'maxSize': _maxCacheSize,
      };
    } catch (e) {
      return {
        'totalItems': 0,
        'expiredItems': 0,
        'validItems': 0,
        'totalSize': 0,
        'maxSize': _maxCacheSize,
        'error': e.toString(),
      };
    }
  }

  // Limpiar caché automáticamente
  static Future<void> _cleanupCache() async {
    try {
      final stats = await getStats();
      final totalItems = stats['totalItems'] ?? 0;
      
      if (totalItems > _maxCacheSize) {
        // Eliminar elementos más antiguos
        await _removeOldestItems(totalItems - _maxCacheSize);
      }
      
      // Eliminar elementos expirados
      await _removeExpiredItems();
    } catch (e) {
      print('Error cleaning up cache: $e');
    }
  }

  // Remover elementos más antiguos
  static Future<void> _removeOldestItems(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final cacheItems = <Map<String, dynamic>>[];
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          final dataKey = key;
          final metadataKey = _getMetadataKey(key.replaceFirst(_cachePrefix, ''));
          
          if (prefs.containsKey(metadataKey)) {
            final metadataJson = prefs.getString(metadataKey);
            if (metadataJson != null) {
              final metadata = jsonDecode(metadataJson);
              cacheItems.add({
                'dataKey': dataKey,
                'metadataKey': metadataKey,
                'created': DateTime.parse(metadata['created']),
              });
            }
          }
        }
      }
      
      // Ordenar por fecha de creación (más antiguos primero)
      cacheItems.sort((a, b) => a['created'].compareTo(b['created']));
      
      // Eliminar los más antiguos
      for (int i = 0; i < count && i < cacheItems.length; i++) {
        final item = cacheItems[i];
        await prefs.remove(item['dataKey']);
        await prefs.remove(item['metadataKey']);
      }
    } catch (e) {
      print('Error removing oldest items: $e');
    }
  }

  // Remover elementos expirados
  static Future<void> _removeExpiredItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          final dataKey = key;
          final metadataKey = _getMetadataKey(key.replaceFirst(_cachePrefix, ''));
          
          if (prefs.containsKey(metadataKey)) {
            final metadataJson = prefs.getString(metadataKey);
            if (metadataJson != null) {
              final metadata = jsonDecode(metadataJson);
              final expiration = DateTime.parse(metadata['expiration']);
              
              if (DateTime.now().isAfter(expiration)) {
                await prefs.remove(dataKey);
                await prefs.remove(metadataKey);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error removing expired items: $e');
    }
  }

  // Generar clave de caché
  static String _getCacheKey(String key) {
    return '$_cachePrefix$key';
  }

  // Generar clave de metadata
  static String _getMetadataKey(String key) {
    return '$_cacheMetadataPrefix$key';
  }

  // Caché con TTL (Time To Live)
  static Future<T?> getWithTTL<T>(String key, Duration ttl) async {
    final data = await get<T>(key);
    if (data != null) {
      // Renovar TTL
      await set(key, data, expiration: ttl);
    }
    return data;
  }

  // Caché para listas con paginación
  static Future<List<T>?> getPaginatedList<T>(String baseKey, int page, int pageSize) async {
    final key = '${baseKey}_page_${page}_size_$pageSize';
    return await get<List<T>>(key);
  }

  static Future<void> setPaginatedList<T>(String baseKey, int page, int pageSize, List<T> data, {Duration? expiration}) async {
    final key = '${baseKey}_page_${page}_size_$pageSize';
    await set(key, data, expiration: expiration);
  }

  // Caché para datos de usuario
  static Future<T?> getUserData<T>(String userId, String dataType) async {
    final key = 'user_${userId}_$dataType';
    return await get<T>(key);
  }

  static Future<void> setUserData<T>(String userId, String dataType, T data, {Duration? expiration}) async {
    final key = 'user_${userId}_$dataType';
    await set(key, data, expiration: expiration);
  }

  // Invalidar caché por patrón
  static Future<void> invalidateByPattern(String pattern) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) && key.contains(pattern)) {
          final dataKey = key;
          final metadataKey = _getMetadataKey(key.replaceFirst(_cachePrefix, ''));
          
          await prefs.remove(dataKey);
          await prefs.remove(metadataKey);
        }
      }
    } catch (e) {
      print('Error invalidating cache by pattern: $e');
    }
  }
} 