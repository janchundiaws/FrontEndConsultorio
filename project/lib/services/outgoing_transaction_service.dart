import 'dart:convert';
import 'package:odontologo/object/outgoing_transaction.dart';
import 'package:odontologo/services/http_interceptor.dart';
import 'package:odontologo/services/logger_service.dart';

class OutgoingTransactionService {
  static const String baseUrl = '/api/inventory/outgoing';

  static Future<List<OutgoingTransaction>> getAllOutgoingTransactions() async {
    try {
      LoggerService.info('Obteniendo transacciones de egreso', tag: 'OUTGOING');
      final response = await HttpInterceptor.get(baseUrl, headers: {});
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          return jsonData.map((e) => OutgoingTransaction.fromJson(e)).toList();
        }
        return [];
      }
      throw Exception('Error al obtener transacciones: ${response.statusCode}');
    } catch (e) {
      LoggerService.error('Error getAllOutgoingTransactions', tag: 'OUTGOING', error: e.toString());
      rethrow;
    }
  }

  static Future<OutgoingTransaction?> getOutgoingTransactionById(int outgoingId) async {
    try {
      LoggerService.info('Obteniendo egreso ID: $outgoingId', tag: 'OUTGOING');
      final response = await HttpInterceptor.get('$baseUrl/$outgoingId', headers: {});
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        Map<String, dynamic> data = jsonData is List ? (jsonData.isNotEmpty ? jsonData.first : null) : jsonData;
        //if (data == null) return null;
        if (data['outgoingId'] == null) return null;
        return OutgoingTransaction.fromJson(data);
      }
      throw Exception('Error al obtener egreso: ${response.statusCode}');
    } catch (e) {
      LoggerService.error('Error getOutgoingTransactionById', tag: 'OUTGOING', error: e.toString());
      rethrow;
    }
  }

  static Future<OutgoingTransaction> createOutgoingTransaction(CreateOutgoingTransaction tx) async {
    try {
      LoggerService.info('Creando egreso: ${tx.transactionNumber}', tag: 'OUTGOING');
      final response = await HttpInterceptor.post(
        baseUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(tx.toJson()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        final data = jsonData is List ? jsonData.first : jsonData;
        return OutgoingTransaction.fromJson(data);
      }
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw Exception(body['message'] ?? 'Error al crear egreso');
    } catch (e) {
      LoggerService.error('Error createOutgoingTransaction', tag: 'OUTGOING', error: e.toString());
      rethrow;
    }
  }

  static Future<OutgoingTransaction> updateOutgoingTransaction(OutgoingTransaction tx) async {
    try {
      LoggerService.info('Actualizando egreso ID: ${tx.outgoingId}', tag: 'OUTGOING');
      final response = await HttpInterceptor.put(
        '$baseUrl/${tx.outgoingId}',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(tx.toJson()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        final data = jsonData is List ? jsonData.first : jsonData;
        return OutgoingTransaction.fromJson(data);
      }
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw Exception(body['message'] ?? 'Error al actualizar egreso');
    } catch (e) {
      LoggerService.error('Error updateOutgoingTransaction', tag: 'OUTGOING', error: e.toString());
      rethrow;
    }
  }

  static Future<bool> deleteOutgoingTransaction(int outgoingId) async {
    try {
      LoggerService.info('Eliminando egreso ID: $outgoingId', tag: 'OUTGOING');
      final response = await HttpInterceptor.delete('$baseUrl/$outgoingId', headers: {});
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw Exception(body['message'] ?? 'Error al eliminar egreso');
    } catch (e) {
      LoggerService.error('Error deleteOutgoingTransaction', tag: 'OUTGOING', error: e.toString());
      rethrow;
    }
  }

  static Future<List<OutgoingTransaction>> searchOutgoingTransactions(String query) async {
    try {
      LoggerService.info('Buscando egresos: $query', tag: 'OUTGOING');
      final response = await HttpInterceptor.get('$baseUrl?search=$query', headers: {});
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          return jsonData.map((e) => OutgoingTransaction.fromJson(e)).toList();
        }
        return [];
      }
      throw Exception('Error en búsqueda: ${response.statusCode}');
    } catch (e) {
      LoggerService.error('Error searchOutgoingTransactions', tag: 'OUTGOING', error: e.toString());
      rethrow;
    }
  }

  static String generateTransactionNumber() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return 'EGR-$year$month$day-$hour$minute$second';
  }
}