/* Autor: Pio enrique Olvera Briones
   Fecha: 27/05/2025
   Descripción: pantalla para consulta/registro de pacientes
*/

import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:button_navigation_bar/button_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'package:odontologo/services/http_interceptor.dart';
import 'package:odontologo/widgets/connection_status.dart';
import 'package:odontologo/services/pdf_service.dart';
import 'package:odontologo/screens/pdf_viewer_screen.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:odontologo/widgets/toast_msg.dart';

// ignore: camel_case_types
class Pacientes extends StatefulWidget {
  const Pacientes({super.key});

  @override
  State<Pacientes> createState() => _PacientesState();
}

// ignore: camel_case_types
class _PacientesState extends State<Pacientes> {
  final _formKey = GlobalKey<FormState>();
  late final PlutoGridStateManager stateManager;
  final List _lisDocumentDetails = [];
  List<PlutoColumn> columns = [];
  final _buscarPacienteController = TextEditingController();
  String _verticalGroupValue = "Document Id";

  @override
  void initState() {
    super.initState();
    columns = _columnsRender();
  }

  bool esPantallaGrande(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      floatingActionButton: ButtonNavigationBar(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        children: [
          ButtonNavigationItem(
            label: " Nuevo",
            height: 40,
            width: 130,
            icon: const Icon(Icons.person_add, color: Colors.white,),
            color: Colors.blue[200],
            onPressed: () async {
              Navigator.pushNamed(context, '/paciente', arguments: 0);
            },
          ),
          ButtonNavigationItem(
            label: " Imprimir",
            height: 40,
            width: 130,
            icon: const Icon(Icons.print, color: Colors.white,), 
            color: Colors.green[200],
            onPressed: () async {
              AwesomeDialog(
                context: context,
                animType: AnimType.bottomSlide,
                dialogType: DialogType.question,
                title: '+ Odontología ',
                desc: '¿Desea generar el PDF del paciente seleccionado?',
                btnOkText: 'SI',
                btnOkOnPress: () async {
                  await _generarYMostrarPdf();
                },
                btnCancelText: 'NO',
                btnCancelOnPress: () {},
              ).show();
            },

          ),
          ButtonNavigationItem(
            label: " Eliminar",
            height: 40,
            width: 130,
            icon: const Icon(Icons.delete_forever_outlined, color: Colors.white,), 
            color: Colors.orange[200],
            onPressed: () async {
              AwesomeDialog(
                context: context,
                animType: AnimType.bottomSlide,
                dialogType: DialogType.question,
                title: '+ Odontología ',
                desc: '¿Desea eliminar el paciente seleccionado?',
                btnOkText: 'SI',
                btnOkOnPress: () async {
                  await _eliminarPaciente();
                },
                btnCancelText: 'NO',
                btnCancelOnPress: () {},
              ).show();
            },
          ),
        ],
      ),

      appBar: AppBar(
        title: const Text('Lista de Pacientes', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),),
        leading: ButtonBack(),
        actions: [
          AppBarConnectionStatus(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ResponsiveGridRow(
                          children: [
                            ResponsiveGridCol(
                              lg: 8,
                              xl: 8,
                              md: 8,
                              sm: 10,
                              xs: 10,
                              child: RadioGroup<String>.builder(
                                  direction: Axis.horizontal,
                                  groupValue: _verticalGroupValue,
                                  horizontalAlignment: MainAxisAlignment.spaceBetween,
                                  onChanged: (value) => setState(() {
                                    _verticalGroupValue = value ?? '';
                                    //print('_verticalGroupValue $_verticalGroupValue');
                                  }),
                                  items: ["Document Id", "Names/Last Names"], // , "History Clinical"
                                  itemBuilder: (item) => RadioButtonBuilder(
                                    item,
                                    textPosition: RadioButtonTextPosition.right,
                                  ),
                                ),
                              )
                          ]),
                        ResponsiveGridRow(
                          children: [
                            ResponsiveGridCol(
                              lg: 8,
                              xl: 8,
                              md: 8,
                              sm: 8,
                              xs: 8,
                              child: Container(
                                padding: const EdgeInsets.all(3.0),
                                child: _buildBuscarPaciente(context),
                              ),
                            ),
                            ResponsiveGridCol(
                              lg: 1,
                              xl: 1,
                              md: 1,
                              sm: 1,
                              xs: 1,
                              child: SizedBox(),
                            ),
                            ResponsiveGridCol(
                                lg: 3,
                                xl: 3,
                                md: 3,
                                sm: 3,
                                xs: 3,
                                child: btnBuscar(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        
                // Detalle Grid
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ResponsiveGridRow(
                          children: [
                            ResponsiveGridCol(
                              xl: 12,
                              md: 12,
                              lg: 12,
                              sm: 12,
                              xs: 12,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height * 0.6,
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                                  child: PlutoGrid(
                                    columns: columns,
                                    rows: rowsLista(_lisDocumentDetails),
                                    mode: PlutoGridMode.normal,
                                    onLoaded: (PlutoGridOnLoadedEvent event) {
                                      stateManager = event.stateManager;
                                      stateManager.setKeepFocus(false);
                                      event.stateManager.setShowColumnFilter(true,);
                                      event.stateManager.setShowColumnFooter(false,);
                                    },
                                    onChanged: (event) {},
                                    onRowDoubleTap: (event) {},
                                    configuration: PlutoGridConfiguration(
                                      style: const PlutoGridStyleConfig(
                                        enableColumnBorderHorizontal: true,
                                        enableCellBorderVertical: true,
                                        enableGridBorderShadow: true,
                                      ),
                                      columnFilter: const PlutoGridColumnFilterConfig(),
                                      columnSize: PlutoGridColumnSizeConfig(
                                        autoSizeMode: isSmallScreen ? PlutoAutoSizeMode.none : PlutoAutoSizeMode.scale,
                                        resizeMode: isSmallScreen ? PlutoResizeMode.normal : PlutoResizeMode.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container btnBuscar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
      child: ElevatedButton.icon(
      label: const Text("Buscar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),),
      style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Colors.lightBlue),
          padding: WidgetStateProperty.all<EdgeInsets>(const EdgeInsets.symmetric(vertical:10,horizontal: 5)
          )),
      onPressed: () async {
        if (_buscarPacienteController.text.trim().isEmpty) {
          ToastMSG.showError(context, 'Ingrese un dato a buscar...', 2);
          return;
        }
        await consultaPacientes();
        setState(() {
          _buscarPacienteController.clear();
        });
      },
      icon: const Icon(Icons.search_rounded, color: Colors.white70,),
      ),
    );
  }

  Future<void> consultaPacientes() async {
    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: 'Procesando...');
    
    _lisDocumentDetails.clear();
    try {
      var url = '/api/patients';
      if (_verticalGroupValue == "Document Id") {
        url = '/api/patients/document/${_buscarPacienteController.text.trim()}';
      } else {
        url = '/api/patients/name/${_buscarPacienteController.text.trim()}';
      }

      final res = await HttpInterceptor.get(url, headers: {});
    
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final jsonData = jsonDecode(res.body);

        jsonData.toList().forEach((element) {
            final birthDateStr = element['birth_date'] ?? '';
            final edadCalculada = birthDateStr.isNotEmpty ? calcularEdad(birthDateStr) : 0;

          _lisDocumentDetails.add({
            'Seleccion': false
            ,'historia': '0'
            ,'cedula': element['document_id']
            , 'apellidos': element['last_name'] 
            , 'nombres': element['name']
            , 'edad': edadCalculada.toString()
            , 'direccion': element['address']
            , 'telefonos': element['phone']
            , 'email': element['email']
            , 'id': element['id']
          }); 
        });
      } 
    
      setState(() {
        if (stateManager.rows.isNotEmpty) {
            stateManager.removeRows(stateManager.rows);
        }
        //print('_lisDocumentDetails $_lisDocumentDetails');
        stateManager.appendRows(rowsLista(_lisDocumentDetails));
      });
      pr.close();
    
    } on Exception catch (e) {
      pr.close();
      AwesomeDialog(
        // ignore: use_build_context_synchronously
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.error,
        title: 'Odontológico',
        desc: e.toString(),
        btnOkText: 'Cerrar',
        btnOkOnPress: () {},
      ).show();
    }
  }

  TextFormField _buildBuscarPaciente(BuildContext context) {
    return TextFormField(
      controller: _buscarPacienteController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 100,
      validator: (value) {
        if(value == null || value.trim().isEmpty){
          return 'Ingrese Dato a Buscar...';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Id / Nombres',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  List<PlutoRow> rowsLista(List info) {
    List<PlutoRow> retorno = [];
    try {
      for (var rowInfo in info) {
        retorno.add(
          PlutoRow(
            cells: {
              'Seleccion': PlutoCell(value: rowInfo['Seleccion'] ? 'SI' : 'NO'),
              'Historia': PlutoCell(value: rowInfo['historia']),
              'Cedula': PlutoCell(value: rowInfo['cedula']),
              'Apellidos': PlutoCell(value: rowInfo['apellidos']),
              'Nombres': PlutoCell(value: rowInfo['nombres']),
              'Edad': PlutoCell(value: rowInfo['edad']),
              'Direccion': PlutoCell(value: rowInfo['direccion']),
              'Telefonos': PlutoCell(value: rowInfo['telefonos']),
              'Email': PlutoCell(value: rowInfo['email']),
              'id2': PlutoCell(value: rowInfo['id']),
            },
          ),
        );
      }
    } on Exception catch (e) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.error,
        title: 'SPA+ ',
        desc: e.toString(),
        btnOkText: 'Cerrar',
        btnOkOnPress: () {},
      ).show();
    }
    return retorno;
  }

  List<PlutoColumn> _columnsRender() {
    Color colorHeader = Colors.lightBlue;
    List<PlutoColumn> list = [];

    list.add(
      PlutoColumn(
        title: '',
        field: 'Seleccion',
        backgroundColor: colorHeader,
        readOnly: false,
        width: 50,
        textAlign: PlutoColumnTextAlign.center,
        frozen: PlutoColumnFrozen.start,
        type: PlutoColumnType.select(['true', 'false']),
        enableFilterMenuItem: false,
        enableContextMenu: false,
        enableHideColumnMenuItem: false,
        enableSetColumnsMenuItem: false,
        enableDropToResize: false,
        enableSorting: false,
        renderer: (rendererContext) {
          final isSelected = rendererContext.cell.value == true || rendererContext.cell.value == 'true';

          return Checkbox(
            value: isSelected,
            onChanged: (value) {
              rendererContext.row.cells['Seleccion']!.value = value == true ? 'true' : 'false';
              rendererContext.stateManager.notifyListeners();
            },
          );
        },
      ),
    );
    list.add(
      PlutoColumn(
        title: 'Historia',
        field: 'Historia',
        backgroundColor: colorHeader,
        readOnly: true,
        width: 100,
        textAlign: PlutoColumnTextAlign.center,
        frozen: PlutoColumnFrozen.start,
        type: PlutoColumnType.text(),
        hide: true,
      ),
    );
    list.add(
      PlutoColumn(
        title: 'Document Id',
        field: 'Cedula',
        backgroundColor: colorHeader,
        width: 140,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
        renderer: (rendererContext) {
          final documentId = rendererContext.cell.value;

          return Tooltip(
            message: 'Editar Paciente',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,  // Puntero tipo mano
              child: GestureDetector(
                onTap: () {
                  final int idPatient = rendererContext.row.cells['id2']?.value;
                  Navigator.pushNamed(context, '/paciente', arguments: idPatient); 
                },
                child: Text(
                  documentId,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    list.add(
      PlutoColumn(
        title: 'Apellidos',
        field: 'Apellidos',
        backgroundColor: colorHeader,
        width: 200, 
        textAlign: PlutoColumnTextAlign.left,
        type: PlutoColumnType.text(),
      ),
    );
    list.add(
      PlutoColumn(
        title: 'Nombres',
        field: 'Nombres',
        backgroundColor: colorHeader,
        width: 200, 
        textAlign: PlutoColumnTextAlign.left,
        type: PlutoColumnType.text(),
      ),
    );
    list.add(
      PlutoColumn(
        title: 'Edad',
        field: 'Edad',
        backgroundColor: colorHeader,
        readOnly: true,
        textAlign: PlutoColumnTextAlign.center,
        width: 85,
        type: PlutoColumnType.number(),
        enableHideColumnMenuItem: false,
      ),
    );
    list.add(
      PlutoColumn(
        title: 'Dirección',
        field: 'Direccion',
        backgroundColor: colorHeader,
        width: 200, 
        textAlign: PlutoColumnTextAlign.left,
        type: PlutoColumnType.text(),
      ),
    );    
    list.add(
      PlutoColumn(
        title: 'Teléfonos',
        field: 'Telefonos',
        backgroundColor: colorHeader,
        readOnly: true,
        width: 180,
        type: PlutoColumnType.text(),
        //hide: true,
        enableHideColumnMenuItem: false,
      ),
    );
    list.add(
      PlutoColumn(
        title: 'E-mail',
        field: 'Email',
        backgroundColor: colorHeader,
        readOnly: true,
        width: 300,
        textAlign: PlutoColumnTextAlign.left,
        type: PlutoColumnType.text(),
      ),
    );

    list.add(
      PlutoColumn(
        title: 'Acción',
        field: 'id2',
        backgroundColor: colorHeader,
        type: PlutoColumnType.number(),
        width: 65,
        minWidth: 50,
        frozen: PlutoColumnFrozen.end,
        textAlign: PlutoColumnTextAlign.center,
        enableContextMenu: false,
        enableColumnDrag: false,
        enableRowDrag: false,
        enableFilterMenuItem: false,
        readOnly: true,
        renderer: (rendererContext) {
          return Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: 'Adicionar/Ver historial',
                  child: IconButton(
                    icon: const Icon(Icons.history_edu, color: Colors.green),
                    onPressed: () {
                      final int idPatient = rendererContext.row.cells['id2']?.value;
                      final String documentId = rendererContext.row.cells['Cedula']?.value;
                      final String name = rendererContext.row.cells['Nombres']?.value;
                      final String lastName = rendererContext.row.cells['Apellidos']?.value;

                      Navigator.pushNamed(context,'/historia',arguments: {'idPatient': idPatient,'documentId': documentId,'name':name,'lastName':lastName},); 
                      //ToastMSG.showInfo(context, 'Press History', 2);
                    },
                    iconSize: 13,
                    padding: const EdgeInsets.all(2),
                  ),
                ),
              ),
              Expanded(
                child: Tooltip(
                  message: 'Agendar Cita',
                  child: IconButton(
                    icon: const Icon(Icons.assignment_add, color: Colors.blue),
                    onPressed: () {
                      final int idPatient = rendererContext.row.cells['id2']?.value;
                      final String documentId = rendererContext.row.cells['Cedula']?.value;
                      final String name = rendererContext.row.cells['Nombres']?.value;
                      final String lastName = rendererContext.row.cells['Apellidos']?.value;
                      final String telefono = rendererContext.row.cells['Telefonos']?.value;
                      final String correo = rendererContext.row.cells['Email']?.value;

                      Navigator.pushNamed(context,'/citas',arguments: {'idPatient': idPatient,'documentId': documentId,'name':name,'lastName':lastName,'telefonos':telefono,'correo':correo},); 
                    },
                    iconSize: 13,
                    padding: const EdgeInsets.all(2),
                  ),
                ),
              ), 
            ],
          );
        },
      ),
    );

    return list;
  }

  int calcularEdad(String fechaNacimientoStr) {
    DateTime fechaNacimiento = DateTime.parse(fechaNacimientoStr);
    DateTime hoy = DateTime.now();

    int edad = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month || 
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  Future<Map<String, dynamic>?> _obtenerDatosCompletosPaciente(int patientId) async {
    try {
      final res = await HttpInterceptor.get('/api/patients/id/$patientId', headers: {});
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final jsonData = jsonDecode(res.body);
        Map<String, dynamic> patientData;
        
        // Manejar tanto array como objeto único
        if (jsonData is List) {
          patientData = jsonData.first;
        } else {
          patientData = jsonData;
        }

        // Calcular edad
        final birthDateStr = patientData['birth_date'] ?? '';
        final edad = birthDateStr.isNotEmpty ? calcularEdad(birthDateStr) : 0;

        return {
          'documentId': patientData['document_id'] ?? '',
          'name': patientData['name'] ?? '',
          'lastName': patientData['last_name'] ?? '',
          'birthDate': patientData['birth_date'] ?? '',
          'edad': edad,
          'address': patientData['address'] ?? '',
          'phone': patientData['phone'] ?? '',
          'email': patientData['email'] ?? '',
          'maritalStatus': patientData['marital_status_id'] ?? '',
          'bloodType': patientData['blood_type_id'] ?? '',
          'observations': patientData['occupation'] ?? 'Sin observaciones',
        };
      }
    } catch (e) {
      //print('Error obteniendo datos del paciente: $e');
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'Error al cargar los datos del paciente: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {
            Navigator.pop(context);
          },
        ).show();
      }
    }
    return null;
  }

  Future<void> _generarYMostrarPdf() async {
    // Obtener el paciente seleccionado
    final selectedRows = stateManager.rows.where((row) {
      final isSelected = row.cells['Seleccion']?.value;
      return isSelected == true || isSelected == 'true';
    }).toList();

    if (selectedRows.isEmpty) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Selección Requerida',
        desc: 'Por favor seleccione un paciente para generar el PDF',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    if (selectedRows.length > 1) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Múltiples Selecciones',
        desc: 'Por favor seleccione solo un paciente para generar el PDF',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    final selectedRow = selectedRows.first;
    final patientId = selectedRow.cells['id2']?.value as int?;
     
    if (patientId == null) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.error,
        title: 'Error',
        desc: 'No se pudo obtener el ID del paciente',
        btnOkText: 'Cerrar',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    // Mostrar diálogo de progreso
    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: 'Generando PDF...');

    try {
      // Obtener datos completos del paciente
      final patientData = await _obtenerDatosCompletosPaciente(patientId);
      
      if (patientData == null) {
        throw Exception('No se pudieron obtener los datos del paciente');
      }

      // Generar PDF
      final pdfBytes = await PdfService.generatePatientPdf(patientData);
      
      pr.close();

      // Mostrar el PDF
      final patientName = '${patientData['name']} ${patientData['lastName']}';
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              pdfBytes: pdfBytes,
              patientName: patientName,
            ),
          ),
        );
      }

    } catch (e) {
      pr.close();
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'Error generando el PDF: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  Future<void> _eliminarPaciente() async {
     // Obtener el paciente seleccionado
     final selectedRows = stateManager.rows.where((row) {
       final isSelected = row.cells['Seleccion']?.value;
       return isSelected == true || isSelected == 'true';
     }).toList();

     if (selectedRows.isEmpty) {
       AwesomeDialog(
         context: context,
         animType: AnimType.bottomSlide,
         dialogType: DialogType.warning,
         title: 'Selección Requerida',
         desc: 'Por favor seleccione un paciente para eliminar',
         btnOkText: 'Entendido',
         btnOkOnPress: () {},
       ).show();
       return;
     }

     if (selectedRows.length > 1) {
       AwesomeDialog(
         context: context,
         animType: AnimType.bottomSlide,
         dialogType: DialogType.warning,
         title: 'Múltiples Selecciones',
         desc: 'Por favor seleccione solo un paciente para eliminar',
         btnOkText: 'Entendido',
         btnOkOnPress: () {},
       ).show();
       return;
     }

     final selectedRow = selectedRows.first;
     final patientId = selectedRow.cells['id2']?.value as int?;
     final patientName = '${selectedRow.cells['Nombres']?.value} ${selectedRow.cells['Apellidos']?.value}';
     
     if (patientId == null) {
       AwesomeDialog(
         context: context,
         animType: AnimType.bottomSlide,
         dialogType: DialogType.error,
         title: 'Error',
         desc: 'No se pudo obtener el ID del paciente',
         btnOkText: 'Cerrar',
         btnOkOnPress: () {},
       ).show();
       return;
     }

     // Confirmación final antes de eliminar
     AwesomeDialog(
       context: context,
       animType: AnimType.bottomSlide,
       dialogType: DialogType.warning,
       title: 'Confirmar Eliminación',
       desc: '¿Está seguro que desea eliminar al paciente:\n\n$patientName?\n\nEsta acción no se puede deshacer.',
       btnOkText: 'ELIMINAR',
       btnOkColor: Colors.red,
       btnOkOnPress: () async {
         await _ejecutarEliminacion(patientId, patientName);
       },
       btnCancelText: 'CANCELAR',
       btnCancelOnPress: () {},
     ).show();
   }

  Future<void> _ejecutarEliminacion(int patientId, String patientName) async {
    // Mostrar diálogo de progreso
    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: 'Eliminando paciente...');

    try {
      // Enviar petición DELETE a la API
      final res = await HttpInterceptor.delete('/api/patients/$patientId', headers: {});
        
      pr.close();

      if (res.statusCode >= 200 && res.statusCode < 300) {
          // Eliminación exitosa
        if (mounted) {
          AwesomeDialog(
            context: context,
            animType: AnimType.bottomSlide,
            dialogType: DialogType.success,
            title: 'Eliminación Exitosa',
            desc: 'El paciente $patientName ha sido eliminado correctamente.',
            btnOkText: 'Aceptar',
            btnOkOnPress: () {
              // Recargar la lista de pacientes
              consultaPacientes();
            },
          ).show();
        }
      } else {
        // Error en la respuesta del servidor
        final responseBody = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        final errorMessage = responseBody['message'] ?? 'Error al eliminar el paciente';
        
        if (mounted) {
          AwesomeDialog(
            context: context,
            animType: AnimType.bottomSlide,
            dialogType: DialogType.error,
            title: 'Error del Servidor',
            desc: errorMessage,
            btnOkText: 'Cerrar',
            btnOkOnPress: () {},
          ).show();
        }
      }

    } catch (e) {
      pr.close();
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error de Conexión',
          desc: 'Error al conectar con el servidor: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }


}


/*
--*-- usar un check dentro de una celda del pluto grid --*--
    PlutoColumn(
      title: 'Activo',
      field: 'activo',
      type: PlutoColumnType.text(), // usamos text pero renderizamos como checkbox
      renderer: (rendererContext) {
        final isChecked = rendererContext.cell.value == true || rendererContext.cell.value == 'true';

        return Center(
          child: Checkbox(
            value: isChecked,
            onChanged: (value) {
              rendererContext.stateManager.changeCellValue(
                rendererContext.cell,
                value == true ? 'true' : 'false',
                force: true,
              );
            },
          ),
        );
      },
    ),

--*-- fin ejemplo de check en plutogrid --*--

*/