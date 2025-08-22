import 'dart:convert';
import 'package:odontologo/object/supplier.dart';
import 'package:odontologo/services/http_interceptor.dart';
import 'package:odontologo/services/logger_service.dart';

class SupplierService {
  static const String baseUrl = '/api/inventory/suppliers';

  // Obtener todos los proveedores
  static Future<List<Supplier>> getAllSuppliers() async {
    try {
      LoggerService.info('Obteniendo lista de proveedores', tag: 'SUPPLIER');
      
      final response = await HttpInterceptor.get(baseUrl, headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        List<Supplier> suppliers = [];
        
        if (jsonData is List) {
          suppliers = jsonData.map((json) => Supplier.fromJson(json)).toList();
        }
        
        LoggerService.info('Proveedores obtenidos: ${suppliers.length}', tag: 'SUPPLIER');
        return suppliers;
      } else {
        throw Exception('Error al obtener proveedores: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error obteniendo proveedores', tag: 'SUPPLIER', error: e.toString());
      rethrow;
    }
  }

  // Obtener un proveedor por ID
  static Future<Supplier?> getSupplierById(int supplierId) async {
    try {
      LoggerService.info('Obteniendo proveedor ID: $supplierId', tag: 'SUPPLIER');
      
      final response = await HttpInterceptor.get('$baseUrl/id/$supplierId', headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        Map<String, dynamic> supplierData;
        
        // Manejar tanto array como objeto único
        if (jsonData is List) {
          if (jsonData.isEmpty) {
            return null;
          }
          supplierData = jsonData.first;
        } else {
          supplierData = jsonData;
        }
        
        final supplier = Supplier.fromJson(supplierData);
        LoggerService.info('Proveedor obtenido: ${supplier.name}', tag: 'SUPPLIER');
        return supplier;
      } else {
        throw Exception('Error al obtener proveedor: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error obteniendo proveedor', tag: 'SUPPLIER', error: e.toString());
      rethrow;
    }
  }

  // Crear un nuevo proveedor
  static Future<Supplier> createSupplier(CreateSupplier supplier) async {
    try {
      LoggerService.info('Creando proveedor: ${supplier.name}', tag: 'SUPPLIER');

      final response = await HttpInterceptor.post(
        baseUrl,
        headers: {},
        body: jsonEncode(supplier.toJson()),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        Map<String, dynamic> supplierData;
        
        // Manejar tanto array como objeto único
        if (jsonData is List) {
          supplierData = jsonData.first;
        } else {
          supplierData = jsonData;
        }
        
        final createdSupplier = Supplier.fromJson(supplierData);
        LoggerService.info('Proveedor creado exitosamente: ${createdSupplier.name}', tag: 'SUPPLIER');
        return createdSupplier;
      } else {
        // Verificar si la respuesta es HTML en lugar de JSON
        if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
          throw Exception('El servidor devolvió una página HTML. Verifique que el endpoint /inventory/suppliers/ esté disponible.');
        }
        
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = errorBody['message'] ?? 'Error al crear proveedor: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      LoggerService.error('Error creando proveedor', tag: 'SUPPLIER', error: e.toString());
      rethrow;
    }
  }

  // Actualizar un proveedor existente
  static Future<Supplier> updateSupplier(Supplier supplier) async {
    try {
      LoggerService.info('Actualizando proveedor ID: ${supplier.supplierId}', tag: 'SUPPLIER');
      
      final response = await HttpInterceptor.put(
        '$baseUrl/${supplier.supplierId}',
        headers: {},
        body: jsonEncode(supplier.toJson()),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        Map<String, dynamic> supplierData;
        
        // Manejar tanto array como objeto único
        if (jsonData is List) {
          supplierData = jsonData.first;
        } else {
          supplierData = jsonData;
        }
        
        final updatedSupplier = Supplier.fromJson(supplierData);
        LoggerService.info('Proveedor actualizado exitosamente: ${updatedSupplier.name}', tag: 'SUPPLIER');
        return updatedSupplier;
      } else {
        // Verificar si la respuesta es HTML en lugar de JSON
        if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
          throw Exception('El servidor devolvió una página HTML. Verifique que el endpoint /inventory/suppliers/ esté disponible.');
        }
        
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = errorBody['message'] ?? 'Error al actualizar proveedor: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      LoggerService.error('Error actualizando proveedor', tag: 'SUPPLIER', error: e.toString());
      rethrow;
    }
  }

  // Eliminar un proveedor
  static Future<bool> deleteSupplier(int supplierId) async {
    try {
      LoggerService.info('Eliminando proveedor ID: $supplierId', tag: 'SUPPLIER');
      
      final response = await HttpInterceptor.delete('$baseUrl/$supplierId', headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        LoggerService.info('Proveedor eliminado exitosamente', tag: 'SUPPLIER');
        return true;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = errorBody['message'] ?? 'Error al eliminar proveedor';
        throw Exception(errorMessage);
      }
    } catch (e) {
      LoggerService.error('Error eliminando proveedor', tag: 'SUPPLIER', error: e.toString());
      rethrow;
    }
  }

  // Buscar proveedores por nombre o código
  static Future<List<Supplier>> searchSuppliers(String query, String filterField) async {
    try {
      LoggerService.info('Buscando proveedores: $query', tag: 'SUPPLIER');

      var url = '$baseUrl/id/$query';
      if (filterField.isNotEmpty) {
        url = '$baseUrl/$filterField/$query';
      }

      final response = await HttpInterceptor.get(url, headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        List<Supplier> suppliers = [];
        
        if (jsonData is List) {
          suppliers = jsonData.map((json) => Supplier.fromJson(json)).toList();
        }
        
        LoggerService.info('Búsqueda completada: ${suppliers.length} resultados', tag: 'SUPPLIER');
        return suppliers;
      } else {
        throw Exception('Error en búsqueda: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error en búsqueda de proveedores', tag: 'SUPPLIER', error: e.toString());
      rethrow;
    }
  }
} 