import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:odontologo/services/http_interceptor.dart';
import 'package:odontologo/services/logger_service.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

class CumpleanosPacientes extends StatefulWidget {
  const CumpleanosPacientes({super.key});

  @override
  State<CumpleanosPacientes> createState() => _CumpleanosPacientesState();
}

class _CumpleanosPacientesState extends State<CumpleanosPacientes> {
  List<Map<String, dynamic>> _pacientesCumpleanos = [];
  bool _isLoading = false;
  final String _mesActual = _obtenerNombreMes(DateTime.now().month);

  @override
  void initState() {
    super.initState();
    // Ejecutar después del primer frame para evitar usar context antes de tiempo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cargarPacientesCumpleanos();
      }
    });
  }

  static String _obtenerNombreMes(int mes) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes - 1];
  }

  static int _calcularEdad(String fechaNacimiento) {
    try {
      final fechaNac = DateTime.parse(fechaNacimiento);
      final hoy = DateTime.now();
      int edad = hoy.year - fechaNac.year;
      if (hoy.month < fechaNac.month || 
          (hoy.month == fechaNac.month && hoy.day < fechaNac.day)) {
        edad--;
      }
      return edad;
    } catch (e) {
      return 0;
    }
  }

  static String _formatearFecha(String fecha) {
    try {
      final fechaObj = DateTime.parse(fecha);
      return '${fechaObj.day.toString().padLeft(2, '0')}/${fechaObj.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha;
    }
  }

  Future<void> _cargarPacientesCumpleanos() async {
    setState(() {
      _isLoading = true;
    });

    ProgressDialog pr = ProgressDialog(context: context);
    bool prShown = false;
    if (mounted) {
      pr.show(max: 600, msg: 'Cargando pacientes...');
      prShown = true;
    }

    try {
      final res = await HttpInterceptor.get('/api/patients', headers: {});
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final jsonData = jsonDecode(res.body);
        final List<dynamic> pacientes = jsonData is List ? jsonData : [jsonData];
        
        final mesActual = DateTime.now().month;
        final pacientesFiltrados = <Map<String, dynamic>>[];

        for (final paciente in pacientes) {
          try {
            final fechaNacimiento = paciente['birth_date'] ?? '';
            if (fechaNacimiento.isNotEmpty) {
              final fechaNac = DateTime.parse(fechaNacimiento);
              if (fechaNac.month == mesActual) {
                pacientesFiltrados.add({
                  'documentId': paciente['document_id'] ?? '',
                  'name': paciente['name'] ?? '',
                  'lastName': paciente['last_name'] ?? '',
                  'phone': paciente['phone'] ?? '',
                  'email': paciente['email'] ?? '',
                  'birthDate': fechaNacimiento,
                  'edad': _calcularEdad(fechaNacimiento),
                  'dia': fechaNac.day,
                });
              }
            }
          } catch (e) {
            LoggerService.warning('Error procesando paciente: $e', tag: 'CUMLEANOS');
          }
        }

        // Ordenar por día del mes
        pacientesFiltrados.sort((a, b) => a['dia'].compareTo(b['dia']));

        setState(() {
          _pacientesCumpleanos = pacientesFiltrados;
        });

        LoggerService.info('Pacientes con cumpleaños cargados: ${pacientesFiltrados.length}', tag: 'CUMLEANOS');
      }
    } catch (e) {
      LoggerService.error('Error cargando pacientes con cumpleaños', tag: 'CUMLEANOS', error: e.toString());
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'Error al cargar los datos: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    } finally {
      if (prShown) {
        pr.close();
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cumpleaños - $_mesActual',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: ButtonBack(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPacientesCumpleanos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pacientesCumpleanos.isEmpty
              ? _buildEmptyState()
              : _buildTable(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cake,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay cumpleaños en $_mesActual',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los pacientes que cumplan años este mes aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
          headingRowColor: WidgetStateProperty.all(Colors.blue[700]),
          columns: const [
            DataColumn(label: Text('Documento')),
            DataColumn(label: Text('Nombres')),
            DataColumn(label: Text('Apellidos')),
            DataColumn(label: Text('Teléfono')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Fecha')),
            DataColumn(label: Text('Edad')),
          ],
          rows: _pacientesCumpleanos.asMap().entries.map((entry) {
            final index = entry.key;
            final paciente = entry.value;
            final isEven = index % 2 == 0;
            
            return DataRow(
              color: WidgetStateProperty.all(
                isEven ? Colors.grey[50] : Colors.white,
              ),
              cells: [
                DataCell(Text(
                  paciente['documentId'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )),
                DataCell(Text(paciente['name'] ?? '')),
                DataCell(Text(paciente['lastName'] ?? '')),
                DataCell(Text(paciente['phone'] ?? '')),
                DataCell(Text(paciente['email'] ?? '')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatearFecha(paciente['birthDate'] ?? '')),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.cake,
                        size: 16,
                        color: Colors.orange[600],
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${paciente['edad']} años',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
} 