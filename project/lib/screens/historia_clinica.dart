import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:odontologo/object/patient.dart';
import 'package:odontologo/object/clinical_history.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:odontologo/services/mayusculas.dart';
import 'package:odontologo/services/clinical_history_service.dart';
import 'package:odontologo/widgets/toast_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:odontologo/services/http_interceptor.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

class HistoriaClinica extends StatefulWidget {
  const HistoriaClinica({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HistoriaClinicaScreen createState() => _HistoriaClinicaScreen();
}

class _HistoriaClinicaScreen extends State<HistoriaClinica>{

  final TextEditingController _idController = TextEditingController();
  TextEditingController cedulaController = TextEditingController();
  TextEditingController nombresController = TextEditingController();
  TextEditingController apellidosController = TextEditingController();
  TextEditingController observacionController = TextEditingController();
  TextEditingController nameFileController = TextEditingController();

  int id = 0;
  bool isReadOnly = false;
  //bool _isGrabado = false;
  bool _isLoading = false;

  late final PlutoGridStateManager stateManager;
  final List<ClinicalHistory> _clinicalHistories = [];
  List<PlutoColumn> columns = [];

// para validación del formulario
final _formKey = GlobalKey<FormState>();

String? fileName;
String? extension;
String? base64File;
bool isUploading = false;

@override
void initState() {
  _limpiarVar();
  super.initState();
  columns = _columnsRender();
  WidgetsBinding.instance.addPostFrameCallback((_) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

  final int? idPatient = args['idPatient'];
  final String? documentId = args['documentId'];
  final String? nombres = args['name'];
  final String? apellidos = args['lastName'];

    if (idPatient != null) {
      // Actualiza el controlador del ID con el valor recibido
      _idController.text = idPatient.toString();
      cedulaController.text = documentId.toString();
      nombresController.text = nombres.toString();
      apellidosController.text = apellidos.toString();
      _cargarDatos(idPatient);
      _cargarHistoriasClinicas(idPatient);
    }
  });
}

void _limpiarVar() {
  _idController.text='0';
  cedulaController.text='';
  nombresController.text = '';
  apellidosController.text = '';

  id = 0;
  isReadOnly = false;
  //_isGrabado = false;
  _isLoading = false;
  
  _limpiarVarFile();
  _clinicalHistories.clear();
}

void _limpiarVarFile() {
  observacionController.text='';
  nameFileController.text='';

  fileName='';
  extension='';
  base64File='';
  isUploading = false;
}

bool soloLetras(String texto) {
  return RegExp(r"^[A-ZÑÁÉÍÓÚÜ\s]+$").hasMatch(texto.toUpperCase());
}

bool esPantallaGrande(BuildContext context) {
  return MediaQuery.of(context).size.width >= 600;
}

Future<void> _cargarDatos(int id) async {
  ProgressDialog pr = ProgressDialog(context: context);
  pr.show(max: 600, msg: 'Procesando Consulta...');

  try {
    final res = await HttpInterceptor.get('/api/patients/id/$id', headers: {});

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final jsonData = jsonDecode(res.body);
      
      // Handle both array and single object responses
      Map<String, dynamic> patientData;
      if (jsonData is List) {
        if (jsonData.isEmpty) {
          throw Exception('No se encontró el paciente');
        }
        patientData = jsonData.first;
      } else {
        patientData = jsonData;
      }
      
      Patient patient = Patient.fromJson(patientData);
      setState(() {
        // actualiza campos de la pantalla con el codigo existente
        _idController.text = patient.id.toString();
        cedulaController.text = patient.documentId;
        apellidosController.text = patient.lastName;
        nombresController.text = patient.name;
      });
    } 
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

Future<void> _cargarHistoriasClinicas(int patientId) async {
  try {
    final historias = await ClinicalHistoryService.getClinicalHistoriesByPatient(patientId);

    if (historias.isNotEmpty) {
      setState(() {
          _clinicalHistories.clear();
          _clinicalHistories.addAll(historias);
        });
    }
  } on Exception catch (e) {
    if (mounted) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.error,
        title: 'Odontológico',
        desc: 'Error al cargar historias clínicas: ${e.toString()}',
        btnOkText: 'Cerrar',
        btnOkOnPress: () {},
      ).show();
    }
  }
}

Future<void> _guardarHistoriaClinica() async {
  if (!_validaDatos()) return;

  setState(() {
    _isLoading = true;
  });

  try {
    final createHistory = CreateClinicalHistory(
      patientId: int.parse(_idController.text),
      observation: observacionController.text.trim(),
      fileName: fileName,
      fileExtension: extension,
      fileBase64: base64File,
    );

    final savedHistory = await ClinicalHistoryService.createClinicalHistory(createHistory);
    
    setState(() {
      _clinicalHistories.add(savedHistory);
      _isLoading = false;
    });

    if (mounted) {
      ToastMSG.showSuccess(context, 'Historia clínica guardada exitosamente', 3);
      Navigator.of(context).pop();
    }
    
    // Limpiar campos del formulario
    _limpiarVarFile();
    
  } on Exception catch (e) {
    setState(() {
      _isLoading = false;
    });
    if (mounted) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.error,
        title: 'Odontológico',
        desc: 'Error al guardar historia clínica: ${e.toString()}',
        btnOkText: 'Cerrar',
        btnOkOnPress: () {},
      ).show();
    }
  }
}

Future<void> pickAndUploadFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom, // FileType.any
    allowedExtensions: ['pdf','jpg','jpeg'],
    withData: true,
  );

  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;
    final fileBytes = file.bytes;
    final name = file.name;
    final ext = file.extension;
        
    if (fileBytes != null) {
      setState(() {
        isUploading = true;
        fileName = name;
        extension = ext;
      });

      final base64 = base64Encode(fileBytes);

      setState(() {
        base64File = base64;
        isUploading = false;
      });
    } else {
      // Usuario canceló
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Odontológico',
          desc: 'Selección cancelada...',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }
}

@override
void dispose() {
  _idController.dispose();
  cedulaController.dispose();
  nombresController.dispose();
  apellidosController.dispose();
  observacionController.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  final isSmallScreen = MediaQuery.of(context).size.width < 600;
  return Scaffold(
    appBar: AppBar(title: Text(_idController.text!='0' ? 'Historia Clinica Paciente Edit (${_idController.text})': 'Historia Clinica Paciente New', 
                              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                  leading: ButtonBack(),
                  ), 
    
    body: Stack(
      children: [ 
        Form(
          key: _formKey,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                      xl: 5,
                      lg: 5,
                      md: 7,
                      sm: 6,
                      xs: 6,
                      child: cedulaPacienteField(context, cedulaController),  
                    ),
                  
                  ],
                ),
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                      xl: 5,
                      lg: 5,
                      md: 5,
                      sm: 5,
                      xs: 5,
                      child: apellidosPacienteField(context, apellidosController), 
                    ),
                    ResponsiveGridCol(
                      xl: 5,
                      lg: 5,
                      md: 5,
                      sm: 5,
                      xs: 5,
                      child: nombresPacienteField(context, nombresController), 
                    ),
                    ResponsiveGridCol(
                        lg: 2,
                        xl: 2,
                        md: 2,
                        sm: 2,
                        xs: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                          child: ElevatedButton.icon(
                          label: Tooltip(message: 'Añedir Historia', 
                                  child: Text(isSmallScreen ? '+ History' : 'Nueva Historia', style: TextStyle(color: Colors.white),),
                                ),
                          style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Colors.green),
                              padding: WidgetStateProperty.all<EdgeInsets>(const EdgeInsets.symmetric(vertical:10,horizontal: 5)
                              )),
                          onPressed: () async {
                             _limpiarVarFile();
                            _mostrarBottomSheet(context);
                          },
                          icon: isSmallScreen ? null : Icon(Icons.app_registration, color: Colors.white,),
                        ),
                        )
                    ),                  
                  ]
                ),

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
                                    rows: rowsLista(_clinicalHistories),
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
      ]
    ),
/*     floatingActionButton: FloatingActionButton(
      onPressed: () async {
        //_mostrarBottomSheet(context);
        ToastMSG.showInfo(context, 'Seleccionar Archivo', 2);
        await pickAndUploadFile();       

          AwesomeDialog(
            // ignore: use_build_context_synchronously
            context: context,
            animType: AnimType.bottomSlide,
            dialogType: DialogType.error,
            title: 'Odontológico',
            desc: 'Base64: ${base64File!.substring(0, 100)}...',
            btnOkText: 'Cerrar',
            btnOkOnPress: () {},
          ).show();


      },
      tooltip: 'Añadir History',
      child: const Icon(Icons.add),
    ), */
  );
}

void _mostrarBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // ⚠️ Esto es clave para ocupar más espacio
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.60, // Casi toda la pantalla 0.95
        minChildSize: 0.25,
        maxChildSize: 1.0, // Permitir expandir a pantalla completa
        builder: (_, controller) {
          return SingleChildScrollView(
            controller: controller,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildStatefulBuilderAddObs(context),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// datos personales -- Historia Clinica

Widget cedulaPacienteField(BuildContext context, TextEditingController cedulaController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: cedulaController,
      showCursor: true,
      maxLength: 15,
      readOnly: _idController.text == '' ? false : true,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: 'Id Documento',
        counterText: "",
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: const Icon(Icons.account_box_sharp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        suffixIcon: _idController.text!='' ? null : IconButton(
          icon: const Icon(Icons.search),
          onPressed: () async {
            FocusScope.of(context).unfocus(); // Cierra el teclado
            ToastMSG.showInfo(context,'Buscando Paciente...', 2);
            _cargarDatos(_idController.text as int);
          },
        ),
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.left,
      onChanged: (value) {
        // Aquí puedes agregar lógica reactiva si necesitas
      },
    ),
  );
}

Widget apellidosPacienteField(BuildContext context, TextEditingController apellidosController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: apellidosController,
      showCursor: true,
      maxLength: 100,
      readOnly: true,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [UpperCaseTextFormatter()],
      decoration: InputDecoration(
        labelText: 'Apellidos',
        counterText: "",
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: const Icon(Icons.co_present_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      textAlign: TextAlign.left,
      onChanged: (value) {
        // Puedes colocar lógica reactiva aquí si es necesario
      },
    ),
  );
}

Widget nombresPacienteField(BuildContext context, TextEditingController nombresController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: nombresController,
      showCursor: true,
      maxLength: 100,
      readOnly: true,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [UpperCaseTextFormatter()],
      decoration: InputDecoration(
        labelText: 'Nombres',
        counterText: "",
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: const Icon(Icons.co_present_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      textAlign: TextAlign.left,
      onChanged: (value) {
        // Puedes colocar lógica reactiva aquí si es necesario
      },
    ),
  );
}

Widget observacionField(BuildContext context, TextEditingController observacionController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: observacionController,
      showCursor: true,
      maxLength: 1000,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      inputFormatters: [UpperCaseTextFormatter()],
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: 'Observación:',
        counterText: "",
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: const Icon(Icons.comment_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      textAlign: TextAlign.left,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese una observación';
        }
        if (value.trim().length < 5) {
          return 'La observación es muy corta';
        }
        return null;
      },
      onChanged: (value) {
        // Puedes aplicar lógica reactiva aquí si es necesario
      },
    ),
  );
}

Widget nameFileField(BuildContext context, TextEditingController nameFileController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: nameFileController,
      showCursor: true,
      maxLength: 100,
      readOnly: true,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [UpperCaseTextFormatter()],
      decoration: InputDecoration(
        labelText: 'Nombre Archivo',
        counterText: "",
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        suffixIcon: IconButton(
          icon: const Icon(Icons.attach_file), // o el ícono que prefieras
          tooltip: 'Seleccionar archivo',
          onPressed: () async {
            //ToastMSG.showInfo(context, 'Limpiando Datos Archivos...', 2);
            //_limpiarVarFile();
            await pickAndUploadFile();
            nameFileController.text = fileName.toString();
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      textAlign: TextAlign.left,
      onChanged: (value) {
        // Puedes colocar lógica reactiva aquí si es necesario
      },
    ),
  );
}

List<PlutoRow> rowsLista(List<ClinicalHistory> historias) {
  List<PlutoRow> retorno = [];
  try {
    for (var historia in historias) {
      retorno.add(
        PlutoRow(
          cells: {
            'Seleccion': PlutoCell(value: false),
            'Apellidos': PlutoCell(value: apellidosController.text),
            'Nombres': PlutoCell(value: nombresController.text),
            'observacion': PlutoCell(value: historia.observation),
            'fecha': PlutoCell(value: historia.createdAt ?? ''),
            'archivo': PlutoCell(value: historia.fileName ?? 'Sin archivo'),
            'id2': PlutoCell(value: historia.id),
          },
        ),
      );
    }
  } on Exception catch (e) {
    AwesomeDialog(
      context: context,
      animType: AnimType.bottomSlide,
      dialogType: DialogType.error,
      title: 'Odontológico',
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
      width: 25,
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
      title: 'Apellidos',
      field: 'Apellidos',
      backgroundColor: colorHeader,
      width: 200, 
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
      hide: true,
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
      hide: true,
    ),
  );
  list.add(
    PlutoColumn(
      title: 'Observación',
      field: 'observacion',
      backgroundColor: colorHeader,
      width: 300, 
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
    ),
  );
  list.add(
    PlutoColumn(
      title: 'Fecha',
      field: 'fecha',
      backgroundColor: colorHeader,
      width: 120, 
      textAlign: PlutoColumnTextAlign.center,
      type: PlutoColumnType.text(),
    ),
  );
  list.add(
    PlutoColumn(
      title: 'Archivo',
      field: 'archivo',
      backgroundColor: colorHeader,
      width: 150, 
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
                message: 'Adicionar historial',
                child: IconButton(
                  icon: const Icon(Icons.history_edu, color: Colors.green),
                  onPressed: () {
                    //final int idPatient = rendererContext.row.cells['id2']?.value;
                    //final String documentId = rendererContext.row.cells['Cedula']?.value;
                    //final String name = rendererContext.row.cells['Nombres']?.value;
                    //final String lastName = rendererContext.row.cells['Apellidos']?.value;

                    //Navigator.pushNamed(context,'/historia',arguments: {'idPatient': idPatient,'documentId': documentId,'name':name,'lastName':lastName},); 
                    ToastMSG.showInfo(context, 'Press Add History', 2);
                  },
                  iconSize: 13,
                  padding: const EdgeInsets.all(2),
                ),
              ),
            ),
/*             Expanded(
              child: Tooltip(
                message: 'Agendar Cita',
                child: IconButton(
                  icon: const Icon(Icons.assignment_add, color: Colors.blue),
                  onPressed: () {
                    ToastMSG.showInfo(context, 'Press Agendar Cita', 2);
                  },
                  iconSize: 13,
                  padding: const EdgeInsets.all(2),
                ),
              ),
            ),  */             
          ],
        );
      },
    ),
  );

  return list;
}

StatefulBuilder _buildStatefulBuilderAddObs(BuildContext content) {
  return StatefulBuilder(
      builder: (context, StateSetter setState) {
        return SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Historia Paciente', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const Divider(color: Colors.blue, indent: 15, endIndent: 15,),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: 
                Column(
                  children: [
                    ResponsiveGridRow(
                      children: [
                        ResponsiveGridCol(
                            lg: 12,
                            xl: 12,
                            md: 12,
                            sm: 12,
                            xs: 12,
                            child: Container(
                              padding: const EdgeInsets.all(5.0),
                              child: observacionField(context, observacionController),
                            )
                        ),
                        ResponsiveGridCol(
                            lg: 12,
                            xl: 12,
                            md: 12,
                            sm: 12,
                            xs: 12,
                            child: Container(
                              padding: const EdgeInsets.all(5.0),
                              child: nameFileField(context, nameFileController),
                            )
                        ),
                      ],
                    ),

                    ResponsiveGridRow(
                      children: [
                        ResponsiveGridCol(
                            lg: 6,
                            xl: 6,
                            md: 6,
                            sm: 6,
                            xs: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton.icon(
                                icon: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                  size: 24.0,
                                ),
                                style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Colors.green),),
                                label: Text(_isLoading ? 'Guardando...' : 'Guardar Datos', style: TextStyle(color: Colors.white),),
                                onPressed: _isLoading ? null : () async {
                                  await _guardarHistoriaClinica();
                                },
                              ),
                            )
                        ),
                        ResponsiveGridCol(
                            lg: 6,
                            xl: 6,
                            md: 6,
                            sm: 6,
                            xs: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.white,
                                  size: 24.0,
                                ),
                                style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Colors.red),),
                                label: const Text('Cancelar', style: TextStyle(color: Colors.white),),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            )
                        )
                      ]
                    ),
                  ],
                ),

              ),
            ],
          ),
        );
      }
  );
}

bool _validaDatos() {
  bool valorRespuesta = true;
  String msg = '';


  if(observacionController.text.isEmpty){
    msg += 'Debe Ingresar Observación...\n';
  }

  if(msg.isNotEmpty){
    valorRespuesta=false;
    AwesomeDialog(
      context: context,
      animType: AnimType.bottomSlide,
      dialogType: DialogType.error,
      title: 'Odontológico ',
      desc: msg.toString(),
      btnOkText: 'Cerrar',
      btnOkOnPress: () {},
    ).show();
  }
  return valorRespuesta;
}

}

