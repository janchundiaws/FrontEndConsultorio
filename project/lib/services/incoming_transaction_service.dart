import 'dart:convert';
import 'package:odontologo/object/incoming_transaction.dart';
import 'package:odontologo/services/http_interceptor.dart';
import 'package:odontologo/services/logger_service.dart';

class IncomingTransactionService {
  static const String baseUrl = '/api/inventory/incoming';

  // Obtener todas las transacciones de ingreso
  static Future<List<IncomingTransaction>> getAllIncomingTransactions() async {
    try {
      LoggerService.info('Obteniendo lista de transacciones de ingreso', tag: 'INCOMING');
      
      final response = await HttpInterceptor.get(baseUrl, headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        List<IncomingTransaction> transactions = [];
        //print('jsonData: ${jsonData.toString()}');
        if (jsonData is List) {
          transactions = jsonData.map((json) => IncomingTransaction.fromJson(json)).toList();
        }
        
        LoggerService.info('Transacciones obtenidas: ${transactions.length}', tag: 'INCOMING');
        return transactions;
      } else {
        throw Exception('Error al obtener transacciones: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error obteniendo transacciones', tag: 'INCOMING', error: e.toString());
      rethrow;
    }
  }

  // Obtener una transacción por ID
  static Future<IncomingTransaction?> getIncomingTransactionById(int incomingId) async {
    try {
      LoggerService.info('Obteniendo transacción ID: $incomingId', tag: 'INCOMING');
      
      final response = await HttpInterceptor.get('$baseUrl/$incomingId', headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        Map<String, dynamic> transactionData;
        
        // Manejar tanto array como objeto único
        if (jsonData is List) {
          if (jsonData.isEmpty) {
            return null;
          }
          transactionData = jsonData.first;
        } else {
          transactionData = jsonData;
        }
        
        final transaction = IncomingTransaction.fromJson(transactionData);
        LoggerService.info('Transacción obtenida: ${transaction.transactionNumber}', tag: 'INCOMING');
        return transaction;
      } else {
        throw Exception('Error al obtener transacción: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error obteniendo transacción', tag: 'INCOMING', error: e.toString());
      rethrow;
    }
  }

  // Crear una nueva transacción de ingreso
  static Future<IncomingTransaction> createIncomingTransaction(CreateIncomingTransaction transaction) async {
    try {
      LoggerService.info('Creando transacción: ${transaction.transactionNumber}', tag: 'INCOMING');
      
      final response = await HttpInterceptor.post(
        baseUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transaction.toJson()),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        Map<String, dynamic> transactionData;
        
        // Manejar tanto array como objeto único
        if (jsonData is List) {
          transactionData = jsonData.first;
        } else {
          transactionData = jsonData;
        }
        
        final createdTransaction = IncomingTransaction.fromJson(transactionData);
        LoggerService.info('Transacción creada exitosamente: ${createdTransaction.transactionNumber}', tag: 'INCOMING');
        return createdTransaction;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = errorBody['message'] ?? 'Error al crear transacción';
        throw Exception(errorMessage);
      }
    } catch (e) {
      LoggerService.error('Error creando transacción', tag: 'INCOMING', error: e.toString());
      rethrow;
    }
  }

  // Actualizar una transacción existente
  static Future<IncomingTransaction> updateIncomingTransaction(IncomingTransaction transaction) async {
    try {
      LoggerService.info('Actualizando transacción ID: ${transaction.incomingId}', tag: 'INCOMING');
      
      final response = await HttpInterceptor.put(
        '$baseUrl/${transaction.incomingId}',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transaction.toJson()),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        Map<String, dynamic> transactionData;
        
        // Manejar tanto array como objeto único
        if (jsonData is List) {
          transactionData = jsonData.first;
        } else {
          transactionData = jsonData;
        }
        
        final updatedTransaction = IncomingTransaction.fromJson(transactionData);
        LoggerService.info('Transacción actualizada exitosamente: ${updatedTransaction.transactionNumber}', tag: 'INCOMING');
        return updatedTransaction;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = errorBody['message'] ?? 'Error al actualizar transacción';
        throw Exception(errorMessage);
      }
    } catch (e) {
      LoggerService.error('Error actualizando transacción', tag: 'INCOMING', error: e.toString());
      rethrow;
    }
  }

  // Eliminar una transacción
  static Future<bool> deleteIncomingTransaction(int incomingId) async {
    try {
      LoggerService.info('Eliminando transacción ID: $incomingId', tag: 'INCOMING');
      
      final response = await HttpInterceptor.delete('$baseUrl/$incomingId', headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        LoggerService.info('Transacción eliminada exitosamente', tag: 'INCOMING');
        return true;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = errorBody['message'] ?? 'Error al eliminar transacción';
        throw Exception(errorMessage);
      }
    } catch (e) {
      LoggerService.error('Error eliminando transacción', tag: 'INCOMING', error: e.toString());
      rethrow;
    }
  }

  // Buscar transacciones por número de transacción o factura
  static Future<List<IncomingTransaction>> searchIncomingTransactions(String query) async {
    try {
      LoggerService.info('Buscando transacciones: $query', tag: 'INCOMING');
      
      final response = await HttpInterceptor.get('$baseUrl?search=$query', headers: {});
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        List<IncomingTransaction> transactions = [];
        
        if (jsonData is List) {
          transactions = jsonData.map((json) => IncomingTransaction.fromJson(json)).toList();
        }
        
        LoggerService.info('Búsqueda completada: ${transactions.length} resultados', tag: 'INCOMING');
        return transactions;
      } else {
        throw Exception('Error en búsqueda: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error en búsqueda de transacciones', tag: 'INCOMING', error: e.toString());
      rethrow;
    }
  }

  // Generar número de transacción automático
  static String generateTransactionNumber() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    
    return 'ING-$year$month$day-$hour$minute$second';
  }
} 