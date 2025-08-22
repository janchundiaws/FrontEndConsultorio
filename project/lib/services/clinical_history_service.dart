import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:odontologo/object/clinical_history.dart';
import 'package:odontologo/variables_globales.dart';

class ClinicalHistoryService {
  static const String baseEndpoint = '/api/clinical-histories';

  // Obtener todas las historias clínicas de un paciente
  static Future<List<ClinicalHistory>> getClinicalHistoriesByPatient(int patientId) async {
    try {
      var headersList = Map<String, String>.from(map);
      headersList['Authorization'] = 'Bearer $token';

      final url = Uri.parse('$baseUrl$baseEndpoint/patient/$patientId');
      final response = await http.get(url, headers: headersList);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => ClinicalHistory.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener historias clínicas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener una historia clínica específica
  static Future<ClinicalHistory> getClinicalHistory(int id) async {
    try {
      var headersList = Map<String, String>.from(map);
      headersList['Authorization'] = 'Bearer $token';

      final url = Uri.parse('$baseUrl$baseEndpoint/$id');
      final response = await http.get(url, headers: headersList);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ClinicalHistory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al obtener historia clínica: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear nueva historia clínica
  static Future<ClinicalHistory> createClinicalHistory(CreateClinicalHistory clinicalHistory) async {
    try {
      var headersList = Map<String, String>.from(map);
      headersList['Authorization'] = 'Bearer $token';

      final url = Uri.parse('$baseUrl$baseEndpoint');
      final response = await http.post(
        url,
        headers: headersList,
        body: jsonEncode(clinicalHistory.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ClinicalHistory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al crear historia clínica: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar historia clínica
  static Future<ClinicalHistory> updateClinicalHistory(int id, CreateClinicalHistory clinicalHistory) async {
    try {
      var headersList = Map<String, String>.from(map);
      headersList['Authorization'] = 'Bearer $token';

      final url = Uri.parse('$baseUrl$baseEndpoint/$id');
      final response = await http.put(
        url,
        headers: headersList,
        body: jsonEncode(clinicalHistory.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ClinicalHistory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al actualizar historia clínica: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar historia clínica
  static Future<bool> deleteClinicalHistory(int id) async {
    try {
      var headersList = Map<String, String>.from(map);
      headersList['Authorization'] = 'Bearer $token';

      final url = Uri.parse('$baseUrl$baseEndpoint/$id');
      final response = await http.delete(url, headers: headersList);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Descargar archivo adjunto
  static Future<String> downloadFile(int clinicalHistoryId) async {
    try {
      var headersList = Map<String, String>.from(map);
      headersList['Authorization'] = 'Bearer $token';

      final url = Uri.parse('$baseUrl$baseEndpoint/$clinicalHistoryId/download');
      final response = await http.get(url, headers: headersList);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else {
        throw Exception('Error al descargar archivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
} 