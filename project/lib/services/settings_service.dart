import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:odontologo/object/transaction_type.dart';
import 'package:odontologo/services/dentist_service.dart';

class SettingsService {
  static const String _settingsPath = 'assets/json/settings.json';
  
  static Map<String, dynamic>? _cachedSettings;
  static List<TransactionType>? _cachedIncomingTransactionTypes;
  static List<TransactionType>? _cachedOutgoingTransactionTypes;
  static List<StatusOption>? _cachedIncomingStatusOptions;
  static List<StatusOption>? _cachedOutgoingStatusOptions;
  static List<Map<String, String>>? _cachedDentists;

  // Cargar configuración completa
  static Future<Map<String, dynamic>> loadSettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    try {
      final String jsonString = await rootBundle.loadString(_settingsPath);
      final Map<String, dynamic> settings = json.decode(jsonString);
      _cachedSettings = settings;
      return settings;
    } catch (e) {
      //print('Error cargando configuración: $e');
      // Retornar configuración por defecto si falla
      return _getDefaultSettings();
    }
  }

  // Obtener tipos de transacción de ingreso
  static Future<List<TransactionType>> getIncomingTransactionTypes() async {
    if (_cachedIncomingTransactionTypes != null) {
      return _cachedIncomingTransactionTypes!;
    }

    try {
      final settings = await loadSettings();
      final List<dynamic> typesJson = settings['transaction_types']['incoming'] ?? [];
      
      _cachedIncomingTransactionTypes = typesJson
          .map((json) => TransactionType.fromJson(json))
          .toList();
      
      return _cachedIncomingTransactionTypes!;
    } catch (e) {
      //print('Error cargando tipos de transacción de ingreso: $e');
      return _getDefaultIncomingTransactionTypes();
    }
  }

  // Obtener tipos de transacción de salida
  static Future<List<TransactionType>> getOutgoingTransactionTypes() async {
    if (_cachedOutgoingTransactionTypes != null) {
      return _cachedOutgoingTransactionTypes!;
    }

    try {
      final settings = await loadSettings();
      final List<dynamic> typesJson = settings['transaction_types']['outgoing'] ?? [];
      
      _cachedOutgoingTransactionTypes = typesJson
          .map((json) => TransactionType.fromJson(json))
          .toList();
      
      return _cachedOutgoingTransactionTypes!;
    } catch (e) {
      //print('Error cargando tipos de transacción de salida: $e');
      return _getDefaultOutgoingTransactionTypes();
    }
  }

  // Obtener doctores desde la API
  static Future<List<Map<String, String>>> getDentists() async {
    if (_cachedDentists != null) {
      return _cachedDentists!;
    }
    
    try {
      // Intentar obtener dentistas desde la API
      final dentists = await DentistService.getDentistsForDropdown();
      
      // Cachear el resultado
      _cachedDentists = dentists;
      
      return dentists;
    } catch (e) {
      //print('Error cargando doctores desde API: $e');
      // En caso de error, intentar cargar desde archivo JSON local
      try {
        final settings = await loadSettings();
        final List<dynamic> dentistsJson = settings['dentists'] ?? [];
        
        _cachedDentists = dentistsJson
            .map((json) => Map<String, String>.from(json))
            .toList();

        return _cachedDentists!;
      } catch (e2) {
        //print('Error cargando doctores desde archivo local: $e2');
        return _getDefaultDentists();
      }
    }
  }

  // Obtener opciones de estado para transacciones de ingreso
  static Future<List<StatusOption>> getIncomingStatusOptions() async {
    if (_cachedIncomingStatusOptions != null) {
      return _cachedIncomingStatusOptions!;
    }

    try {
      final settings = await loadSettings();
      final List<dynamic> statusJson = settings['status_options']['incoming'] ?? [];
      
      _cachedIncomingStatusOptions = statusJson
          .map((json) => StatusOption.fromJson(json))
          .toList();
      
      return _cachedIncomingStatusOptions!;
    } catch (e) {
      //print('Error cargando opciones de estado de ingreso: $e');
      return _getDefaultIncomingStatusOptions();
    }
  }

  // Obtener opciones de estado para transacciones de salida
  static Future<List<StatusOption>> getOutgoingStatusOptions() async {
    if (_cachedOutgoingStatusOptions != null) {
      return _cachedOutgoingStatusOptions!;
    }

    try {
      final settings = await loadSettings();
      final List<dynamic> statusJson = settings['status_options']['outgoing'] ?? [];
      
      _cachedOutgoingStatusOptions = statusJson
          .map((json) => StatusOption.fromJson(json))
          .toList();
      
      return _cachedOutgoingStatusOptions!;
    } catch (e) {
      //print('Error cargando opciones de estado de salida: $e');
      return _getDefaultOutgoingStatusOptions();
    }
  }

  // Obtener configuración de la aplicación
  static Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final settings = await loadSettings();
      return settings['app_settings'] ?? {};
    } catch (e) {
      //print('Error cargando configuración de la app: $e');
      return _getDefaultAppSettings();
    }
  }

  // Limpiar caché (útil para testing o recarga)
  static void clearCache() {
    _cachedSettings = null;
    _cachedIncomingTransactionTypes = null;
    _cachedOutgoingTransactionTypes = null;
    _cachedIncomingStatusOptions = null;
    _cachedOutgoingStatusOptions = null;
    _cachedDentists = null;
  }

  // Configuraciones por defecto
  static Map<String, dynamic> _getDefaultSettings() {
    return {
      'transaction_types': {
        'incoming': _getDefaultIncomingTransactionTypes().map((t) => t.toJson()).toList(),
        'outgoing': _getDefaultOutgoingTransactionTypes().map((t) => t.toJson()).toList(),
      },
      'status_options': {
        'incoming': _getDefaultIncomingStatusOptions().map((s) => s.toJson()).toList(),
        'outgoing': _getDefaultOutgoingStatusOptions().map((s) => s.toJson()).toList(),
      },
      'app_settings': _getDefaultAppSettings(),
    };
  }

  static List<TransactionType> _getDefaultIncomingTransactionTypes() {
    return [
      TransactionType(
        code: 'PURCHASE',
        name: 'Compra',
        description: 'Compra de suministros a proveedores',
        color: '#4CAF50',
      ),
      TransactionType(
        code: 'DONATION',
        name: 'Donación',
        description: 'Suministros recibidos como donación',
        color: '#2196F3',
      ),
      TransactionType(
        code: 'RETURN',
        name: 'Devolución',
        description: 'Devolución de suministros por parte del cliente',
        color: '#FF9800',
      ),
      TransactionType(
        code: 'ADJUSTMENT',
        name: 'Ajuste',
        description: 'Ajuste de inventario por conteo físico',
        color: '#9C27B0',
      ),
    ];
  }

  static List<TransactionType> _getDefaultOutgoingTransactionTypes() {
    return [
      TransactionType(
        code: 'SALE',
        name: 'Venta',
        description: 'Venta de suministros a clientes',
        color: '#E91E63',
      ),
      TransactionType(
        code: 'CONSUMPTION',
        name: 'Consumo',
        description: 'Consumo interno del consultorio',
        color: '#795548',
      ),
      TransactionType(
        code: 'DAMAGED',
        name: 'Dañado',
        description: 'Suministros dañados o vencidos',
        color: '#F44336',
      ),
    ];
  }

  static List<StatusOption> _getDefaultIncomingStatusOptions() {
    return [
      StatusOption(
        code: 'PENDING',
        name: 'Pendiente',
        description: 'Transacción pendiente de procesar',
        color: '#FF9800',
      ),
      StatusOption(
        code: 'APPROVED',
        name: 'Aprobada',
        description: 'Transacción aprobada y procesada',
        color: '#4CAF50',
      ),
      StatusOption(
        code: 'REJECTED',
        name: 'Rechazada',
        description: 'Transacción rechazada',
        color: '#F44336',
      ),
    ];
  }

  static List<StatusOption> _getDefaultOutgoingStatusOptions() {
    return [
      StatusOption(
        code: 'PENDING',
        name: 'Pendiente',
        description: 'Transacción pendiente de procesar',
        color: '#FF9800',
      ),
      StatusOption(
        code: 'PROCESSED',
        name: 'Procesada',
        description: 'Transacción procesada y entregada',
        color: '#4CAF50',
      ),
      StatusOption(
        code: 'CANCELLED',
        name: 'Cancelada',
        description: 'Transacción cancelada',
        color: '#9E9E9E',
      ),
    ];
  }

  static Map<String, dynamic> _getDefaultAppSettings() {
    return {
      'default_currency': 'USD',
      'default_language': 'es',
      'date_format': 'dd/MM/yyyy',
      'decimal_places': 2,
      'pagination': {
        'default_page_size': 20,
        'max_page_size': 100,
      },
      'timeout': {
        'api_request': 30000,
        'connection_check': 5000,
      },
    };
  }

  // Obtener doctores por defecto
  static List<Map<String, String>> _getDefaultDentists() {
    return [
      {'codigo': '0', 'descripcion': 'Sin selección'},
    ];
  }

} 