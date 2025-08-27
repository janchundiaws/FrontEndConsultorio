import 'dart:convert';
import 'package:odontologo/object/inventory_stock.dart';
import 'package:odontologo/services/http_interceptor.dart';
import 'package:odontologo/services/logger_service.dart';

class InventoryStockService {
  static const String _endpoint = '/api/inventory/stock';

  // Obtener el stock de inventario
  static Future<List<InventoryStock>> getInventoryStock() async {
    try {
      LoggerService.info('Obteniendo datos de stock', tag: 'INVENTORY_STOCK');

      final response = await HttpInterceptor.get(_endpoint, headers: {});
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => InventoryStock.fromJson(json)).toList();
      } else {
        LoggerService.error('Error al obtener stock: ${response.statusCode}', tag: 'INVENTORY_STOCK');
        throw Exception('Error al obtener stock: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error obteniendo datos de stock', tag: 'INVENTORY_STOCK', error: e.toString());
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener stock con filtros opcionales
  static Future<List<InventoryStock>> getInventoryStockWithFilters({
    String? category,
    String? stockStatus,
    String? warehouseLocation,
  }) async {
    try {
      final stockList = await getInventoryStock();
      
      List<InventoryStock> filteredList = stockList;

      if (category != null && category.isNotEmpty) {
        filteredList = filteredList.where((item) => item.category == category).toList();
      }

      if (stockStatus != null && stockStatus.isNotEmpty) {
        filteredList = filteredList.where((item) => item.stockStatus == stockStatus).toList();
      }

      if (warehouseLocation != null && warehouseLocation.isNotEmpty) {
        filteredList = filteredList.where((item) => 
          item.warehouseLocation.toLowerCase().contains(warehouseLocation.toLowerCase())
        ).toList();
      }

      return filteredList;
    } catch (e) {
      throw Exception('Error al filtrar stock: $e');
    }
  }

  // Obtener estadísticas del stock
  static Map<String, dynamic> getStockStatistics(List<InventoryStock> stockList) {
    if (stockList.isEmpty) {
      return {
        'totalItems': 0,
        'totalValue': 0.0,
        'lowStockItems': 0,
        'expiredItems': 0,
        'normalStockItems': 0,
      };
    }

    double totalValue = 0.0;
    int lowStockItems = 0;
    int expiredItems = 0;
    int normalStockItems = 0;

    final now = DateTime.now();

    for (final item in stockList) {
      // Calcular valor total
      final quantity = double.tryParse(item.totalQuantity) ?? 0.0;
      final cost = double.tryParse(item.averageCost) ?? 0.0;
      totalValue += quantity * cost;

      // Contar items con stock bajo
      final availableQty = double.tryParse(item.availableQuantity) ?? 0.0;
      if (availableQty <= item.minStock) {
        lowStockItems++;
      }

      // Contar items expirados
      if (item.expirationDate.isNotEmpty) {
        try {
          final expirationDate = DateTime.parse(item.expirationDate);
          if (expirationDate.isBefore(now)) {
            expiredItems++;
          }
        } catch (e) {
          // Ignorar fechas inválidas
        }
      }

      // Contar items con stock normal
      if (item.stockStatus == 'NORMAL') {
        normalStockItems++;
      }
    }

    return {
      'totalItems': stockList.length,
      'totalValue': totalValue,
      'lowStockItems': lowStockItems,
      'expiredItems': expiredItems,
      'normalStockItems': normalStockItems,
    };
  }
} 