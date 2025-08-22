import 'dart:convert';
import 'package:odontologo/object/master_supply.dart';
import 'package:odontologo/object/inventory_models.dart';
import 'package:odontologo/services/http_interceptor.dart';
import 'package:odontologo/services/logger_service.dart';

class MasterSupplyService {
  static const String baseUrl = '/api/inventory/supplies';
  static const String unitsUrl = '/api/inventory/units';
  static const String categoriesUrl = '/api/inventory/categories';

  // ==================== MASTER SUPPLIES ====================

  // Obtener todos los suministros
  static Future<List<MasterSupply>> getAllSupplies() async {
    try {
      LoggerService.info('Obteniendo lista de suministros', tag: 'SUPPLY');
      
      final response = await HttpInterceptor.get(baseUrl, headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        List<MasterSupply> supplies = [];
        //print('jsonData: ${jsonData.toString()}');
        if (jsonData is List) {
          supplies = jsonData.map((json) => MasterSupply.fromJson(json)).toList();
        }
        
        LoggerService.info('Suministros obtenidos: ${supplies.length}', tag: 'SUPPLY');
        return supplies;
      } else {
        throw Exception('Error al obtener suministros: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error obteniendo suministros', tag: 'SUPPLY', error: e.toString());
      rethrow;
    }
  }

  // Obtener un suministro por ID
  static Future<MasterSupply?> getSupplyById(int supplyId) async {
    try {
      LoggerService.info('Obteniendo suministro ID: $supplyId', tag: 'SUPPLY');
      
      final response = await HttpInterceptor.get('$baseUrl/$supplyId', headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        Map<String, dynamic> supplyData;
        
        // Manejar tanto array como objeto único
        if (jsonData is List) {
          if (jsonData.isEmpty) {
            return null;
          }
          supplyData = jsonData.first;
        } else {
          supplyData = jsonData;
        }
        
        final supply = MasterSupply.fromJson(supplyData);
        LoggerService.info('Suministro obtenido: ${supply.name}', tag: 'SUPPLY');
        return supply;
      } else {
        throw Exception('Error al obtener suministro: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error obteniendo suministro', tag: 'SUPPLY', error: e.toString());
      rethrow;
    }
  }

  // Crear un nuevo suministro
  static Future<MasterSupply> createSupply(CreateMasterSupply supply) async {
    try {
      LoggerService.info('Creando suministro: ${supply.name}', tag: 'SUPPLY');
      
      final response = await HttpInterceptor.post(
        baseUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(supply.toJson()),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        Map<String, dynamic> supplyData;
        
        // Manejar tanto array como objeto único
        if (jsonData is List) {
          supplyData = jsonData.first;
        } else {
          supplyData = jsonData;
        }
        
        final createdSupply = MasterSupply.fromJson(supplyData);
        LoggerService.info('Suministro creado exitosamente: ${createdSupply.name}', tag: 'SUPPLY');
        return createdSupply;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = errorBody['message'] ?? 'Error al crear suministro';
        throw Exception(errorMessage);
      }
    } catch (e) {
      LoggerService.error('Error creando suministro', tag: 'SUPPLY', error: e.toString());
      rethrow;
    }
  }

  // Actualizar un suministro existente
  static Future<MasterSupply> updateSupply(MasterSupply supply) async {
    try {
      LoggerService.info('Actualizando suministro ID: ${supply.supplyId}', tag: 'SUPPLY');
      
      final response = await HttpInterceptor.put(
        '$baseUrl/${supply.supplyId}',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(supply.toJson()),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        Map<String, dynamic> supplyData;
        
        // Manejar tanto array como objeto único
        if (jsonData is List) {
          supplyData = jsonData.first;
        } else {
          supplyData = jsonData;
        }
        
        final updatedSupply = MasterSupply.fromJson(supplyData);
        LoggerService.info('Suministro actualizado exitosamente: ${updatedSupply.name}', tag: 'SUPPLY');
        return updatedSupply;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = errorBody['message'] ?? 'Error al actualizar suministro';
        throw Exception(errorMessage);
      }
    } catch (e) {
      LoggerService.error('Error actualizando suministro', tag: 'SUPPLY', error: e.toString());
      rethrow;
    }
  }

  // Eliminar un suministro
  static Future<bool> deleteSupply(int supplyId) async {
    try {
      LoggerService.info('Eliminando suministro ID: $supplyId', tag: 'SUPPLY');
      
      final response = await HttpInterceptor.delete('$baseUrl/$supplyId', headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        LoggerService.info('Suministro eliminado exitosamente', tag: 'SUPPLY');
        return true;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = errorBody['message'] ?? 'Error al eliminar suministro';
        throw Exception(errorMessage);
      }
    } catch (e) {
      LoggerService.error('Error eliminando suministro', tag: 'SUPPLY', error: e.toString());
      rethrow;
    }
  }

  // Buscar suministros por nombre o código
  static Future<List<MasterSupply>> searchSupplies(String query, String filterField) async {
    try {
      LoggerService.info('Buscando suministros: $query', tag: 'SUPPLY');
      var url = '$baseUrl/id/$query';

      if (filterField.isNotEmpty) {
        url = '$baseUrl/$filterField/$query';
      }

      final response = await HttpInterceptor.get(url, headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        List<MasterSupply> supplies = [];
        
        if (jsonData is List) {
          supplies = jsonData.map((json) => MasterSupply.fromJson(json)).toList();
        }
        
        LoggerService.info('Búsqueda completada: ${supplies.length} resultados', tag: 'SUPPLY');
        return supplies;
      } else {
        throw Exception('Error en búsqueda: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error en búsqueda de suministros', tag: 'SUPPLY', error: e.toString());
      rethrow;
    }
  }

  // ==================== UNITS OF MEASURE ====================

  // Obtener todas las unidades de medida
  static Future<List<UnitOfMeasure>> getAllUnits() async {
    try {
      LoggerService.info('Obteniendo unidades de medida', tag: 'UNITS');
      
      final response = await HttpInterceptor.get(unitsUrl, headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        List<UnitOfMeasure> units = [];
        
        if (jsonData is List) {
          units = jsonData.map((json) => UnitOfMeasure.fromJson(json)).toList();
        }
        
        LoggerService.info('Unidades obtenidas: ${units.length}', tag: 'UNITS');
        return units;
      } else {
        throw Exception('Error al obtener unidades: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error obteniendo unidades', tag: 'UNITS', error: e.toString());
      rethrow;
    }
  }

  // ==================== SUPPLY CATEGORIES ====================

  // Obtener todas las categorías
  static Future<List<SupplyCategory>> getAllCategories() async {
    try {
      LoggerService.info('Obteniendo categorías de suministros', tag: 'CATEGORIES');
      
      final response = await HttpInterceptor.get(categoriesUrl, headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        List<SupplyCategory> categories = [];
        
        if (jsonData is List) {
          categories = jsonData.map((json) => SupplyCategory.fromJson(json)).toList();
        }
        
        LoggerService.info('Categorías obtenidas: ${categories.length}', tag: 'CATEGORIES');
        return categories;
      } else {
        throw Exception('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error obteniendo categorías', tag: 'CATEGORIES', error: e.toString());
      rethrow;
    }
  }
}