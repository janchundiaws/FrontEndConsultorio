import 'dart:convert';
import 'package:odontologo/object/dentist.dart';
import 'package:odontologo/services/http_interceptor.dart';
import 'package:odontologo/services/logger_service.dart';

class DentistService {
  static const String baseUrl = '/api/specialtyDentists';

  // Obtener todos los dentistas desde la API
  static Future<List<Dentist>> getAllDentists() async {
    try {
      LoggerService.info('Obteniendo dentistas', tag: 'DENTIST');
      final response = await HttpInterceptor.get(baseUrl, headers: {});

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        LoggerService.info('Dentistas obtenidos: ${jsonData.length}', tag: 'DENTIST');
        return jsonData.map((json) => Dentist.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener dentistas: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      LoggerService.error('Error al obtener dentistas', tag: 'DENTIST', error: e.toString());
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener dentistas en formato de dropdown (compatible con el código existente)
  static Future<List<Map<String, String>>> getDentistsForDropdown() async {
    try {
      final dentists = await getAllDentists();
      
      // Convertir a formato de dropdown
      final dropdownList = dentists.map((dentist) => dentist.toDropdownFormat()).toList();
      
      // Agregar opción por defecto al inicio
      dropdownList.insert(0, {'codigo': '0', 'descripcion': 'Seleccione un dentista'});
      
      return dropdownList;
    } catch (e) {
      // En caso de error, retornar lista por defecto
      return [
        {'codigo': '0', 'descripcion': 'Error al cargar dentistas'},
      ];
    }
  }

  // Buscar dentista por ID
  static Future<Dentist?> getDentistById(int id) async {
    try {
      final dentists = await getAllDentists();
      return dentists.firstWhere((dentist) => dentist.id == id);
    } catch (e) {
      return null;
    }
  }

  // Buscar dentistas por especialidad
  static Future<List<Dentist>> getDentistsBySpecialty(String specialty) async {
    try {
      final dentists = await getAllDentists();
      return dentists.where((dentist) => 
        dentist.especialidad.toLowerCase().contains(specialty.toLowerCase())
      ).toList();
    } catch (e) {
      return [];
    }
  }
} 