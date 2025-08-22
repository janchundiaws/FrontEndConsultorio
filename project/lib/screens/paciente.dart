import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:odontologo/object/create_patient.dart';
import 'package:odontologo/object/patient.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:odontologo/services/mayusculas.dart';
import 'package:odontologo/widgets/toast_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:odontologo/services/http_interceptor.dart';

import 'package:sn_progress_dialog/progress_dialog.dart';

class Paciente extends StatefulWidget {
  const Paciente({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PacienteScreen createState() => _PacienteScreen();
}

class _PacienteScreen extends State<Paciente>{
  //Offset _menuPosition = const Offset(300, 500); // Posición inicial del botón

  final TextEditingController _idController = TextEditingController();
  TextEditingController tipoDocController = TextEditingController();
  TextEditingController cedulaController = TextEditingController();
  TextEditingController nombresController = TextEditingController();
  TextEditingController apellidosController = TextEditingController();
  TextEditingController correoController = TextEditingController();
  TextEditingController fechaNacimientoController = TextEditingController();
  TextEditingController edadController = TextEditingController();
  TextEditingController direccionController = TextEditingController();
  TextEditingController telefonosController = TextEditingController();
  TextEditingController generoController = TextEditingController();
  TextEditingController estadoCivilController = TextEditingController();
  TextEditingController tipoSangreController = TextEditingController();
  TextEditingController ocupacionReferenciaController = TextEditingController();

  int id = 0;
  bool isReadOnly = false;
  String? _valueGenero='X';
  String? _valueTipoDoc='0';
  String? _valueEstadoCivil='0';
  String? _valueTipoSangre='0';
  bool _isGrabado = false;

final List<Map<String, String>> _genero = [
  {'codigo': 'X', 'descripcion': '-- Sin Selección --'},
  {'codigo': 'M', 'descripcion': 'Masculino'},
  {'codigo': 'F', 'descripcion': 'Femenino'},
 ];

final List<Map<String, String>> _tipoDoc =  [];

final List<Map<String, String>> _estadoCivil =  [];

final List<Map<String, String>> _tipoSangre =  [];

// Expresión regular estándar para correos electrónicos válidos
final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
// para validación del formulario
final _formKey = GlobalKey<FormState>();

@override
void initState() {
  super.initState();
  _limpiarVar();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final int? idPatient = ModalRoute.of(context)?.settings.arguments as int?;

    llamadas();

    if (idPatient != null) {
      // Actualiza el controlador del ID con el valor recibido
      _idController.text = idPatient.toString();
      llamadas2(idPatient);
    }
  });
}

void llamadas() async {
  await _cargarDatosIni();
}

void llamadas2(int idPatient) async {
  await _cargarDatos(idPatient);
}

void _limpiarVar() {
  _idController.text='0';
  tipoDocController.text='';
  cedulaController.text='';
  nombresController.text = '';
  apellidosController.text = '';
  correoController.text = '';
  fechaNacimientoController.text = '';
  edadController.text = '';
  direccionController.text = '';
  telefonosController.text = '';
  generoController.text = '0';
  estadoCivilController.text = '';
  ocupacionReferenciaController.text='';
  tipoSangreController.text = '';

  _valueGenero = 'X';
  _valueTipoDoc='0';
  _valueEstadoCivil='0';
  _valueTipoSangre='0';
  id = 0;
  isReadOnly = false;
  _isGrabado = false;
}

void actualizarEdad(DateTime fechaNacimiento, TextEditingController edadController) {
  final today = DateTime.now();
  int edad = today.year - fechaNacimiento.year;
  if (today.month < fechaNacimiento.month ||
      (today.month == fechaNacimiento.month && today.day < fechaNacimiento.day)) {
    edad--;
  }
  setState(() {
    edadController.text = edad.toString();
  });
}

bool soloLetras(String texto) {
  return RegExp(r"^[A-ZÑÁÉÍÓÚÜ\s]+$").hasMatch(texto.toUpperCase());
}

bool esPantallaGrande(BuildContext context) {
  return MediaQuery.of(context).size.width >= 600;
}

bool validarCedulaEcuatoriana(String cedula) {
  if (cedula.length != 10) return false;
  final province = int.tryParse(cedula.substring(0, 2));
  final thirdDigit = int.tryParse(cedula[2]);

  if (province == null || thirdDigit == null || province < 1 || province > 24 || thirdDigit >= 6) {
    return false;
  }

  int suma = 0;
  for (var i = 0; i < 9; i++) {
    int num = int.parse(cedula[i]);
    if (i % 2 == 0) {
      num *= 2;
      if (num > 9) num -= 9;
    }
    suma += num;
  }

  final digitoVerificador = (10 - (suma % 10)) % 10;
  return digitoVerificador == int.parse(cedula[9]);
}

void _guardarDatos() async {
  if (_formKey.currentState?.validate() ?? false) {
    // ✅ Formulario válido, guardar datos
    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: 'Procesando Grabar...');

    CreatePatient objPatient = CreatePatient(
      documentTypeId: tipoDocController.text,
      documentId: cedulaController.text,
      name: nombresController.text,
      lastName: apellidosController.text,
      phone: telefonosController.text,
      address: direccionController.text,
      email: correoController.text,
      birthDate: DateTime.parse(fechaNacimientoController.text),
      gender: generoController.text,
      maritalStatusId: estadoCivilController.text,
      bloodTypeId: tipoSangreController.text,
      occupation: ocupacionReferenciaController.text
    );

    try {
      final res = await HttpInterceptor.post('/api/patients', headers: {}, body: jsonEncode(objPatient));
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        Patient patient = Patient.fromJson(jsonDecode(res.body));

        setState(() {
          _idController.text = patient.id.toString();
          _isGrabado = true;
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

  } else {
    // ❌ Formulario inválido, mostrar error
    ToastMSG.showError(context, 'Por favor, complete el formulario', 2);
  }
}

void _updateDatos() async {
  if (_formKey.currentState?.validate() ?? false) {
    // ✅ Formulario válido, guardar datos
    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: 'Procesando Actualización...');

    CreatePatient objPatient = CreatePatient(
      documentTypeId: tipoDocController.text,
      documentId: cedulaController.text,
      name: nombresController.text,
      lastName: apellidosController.text,
      phone: telefonosController.text,
      address: direccionController.text,
      email: correoController.text,
      birthDate: DateTime.parse(fechaNacimientoController.text),
      gender: generoController.text,
      maritalStatusId: estadoCivilController.text,
      bloodTypeId: tipoSangreController.text,
      occupation: ocupacionReferenciaController.text
    );

    try {
      final res = await HttpInterceptor.put('/api/patients/${_idController.text}', headers: {}, body: jsonEncode(objPatient));
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        Patient patient = Patient.fromJson(jsonDecode(res.body));

        setState(() {
          _idController.text = patient.id.toString();
          _isGrabado = true;
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

  } else {
    // ❌ Formulario inválido, mostrar error
    ToastMSG.showError(context, 'Por favor, complete el formulario', 2);
  }
}

Future<void> _cargarDatosIni() async {
  List<Map<String, String>> tipoDoc2 =  [];
  List<Map<String, String>> tipoSangre2 = [];
  List<Map<String, String>> estadoCivil3 = [];
  try {
    // tipo de documentos
    final res0 = await HttpInterceptor.get('/api/documentType', headers: {});

    if (res0.statusCode >= 200 && res0.statusCode < 300) {
      final jsonData0 = jsonDecode(res0.body);

      tipoDoc2.add({'codigo': '0', 'descripcion': '-- Sin Selección --'});
      jsonData0.toList().forEach((element) {
        tipoDoc2.add({
          'codigo': element['id'],
          'descripcion': element['name']
        });
      });
    } 

    // tipo sangre
    final res2 = await HttpInterceptor.get('/api/bloodType', headers: {});

    if (res2.statusCode >= 200 && res2.statusCode < 300) {
      final jsonData2 = jsonDecode(res2.body);

      tipoSangre2.add({'codigo': '0', 'descripcion': '-- Sin Selección --'});
      jsonData2.toList().forEach((element2) {
        tipoSangre2.add({
          'codigo': element2['id'],
          'descripcion': element2['name']
        });
      });
    }   

    // estado civil
    final res3 = await HttpInterceptor.get('/api/maritalStatus', headers: {});

    if (res3.statusCode >= 200 && res3.statusCode < 300) {
      final jsonData3 = jsonDecode(res3.body);

      estadoCivil3.add({'codigo': '0', 'descripcion': '-- Sin Selección --'});
      jsonData3.toList().forEach((element2) {
        estadoCivil3.add({
          'codigo': element2['id'],
          'descripcion': element2['name']
        });
      });
    }  

    setState(() {
      _tipoDoc.addAll(tipoDoc2);
      _tipoSangre.addAll(tipoSangre2);
      _estadoCivil.addAll(estadoCivil3);
    });

  } on Exception catch (e) {
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
        tipoDocController.text = patient.documentTypeId;
        cedulaController.text = patient.documentId;
        apellidosController.text = patient.lastName;
        nombresController.text = patient.name;
        direccionController.text = patient.address;
        correoController.text = patient.email;
        generoController.text = patient.gender;
        fechaNacimientoController.text = patient.birthDate.toString().substring(0,10);
        actualizarEdad(DateTime.parse(fechaNacimientoController.text), edadController);
        estadoCivilController.text = patient.maritalStatusId;
        telefonosController.text = patient.phone;
        tipoSangreController.text = patient.bloodTypeId;
        ocupacionReferenciaController.text = patient.occupation;
        // valores de dropdown
        _valueTipoDoc = tipoDocController.text;
        _valueGenero = generoController.text;
        _valueEstadoCivil = estadoCivilController.text;
        _valueTipoSangre = tipoSangreController.text;

      });
    } 
    pr.close();
  } on Exception catch (e) {
    pr.close();
    if (mounted) {
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
  }
}

@override
void dispose() {
  _idController.dispose();
  tipoDocController.dispose();
  cedulaController.dispose();
  nombresController.dispose();
  apellidosController.dispose();
  correoController.dispose();
  fechaNacimientoController.dispose();
  edadController.dispose();
  direccionController.dispose();
  telefonosController.dispose();
  generoController.dispose();
  estadoCivilController.dispose();
  tipoSangreController.dispose();
  ocupacionReferenciaController.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text(_idController.text!='0' ? 'Datos General Paciente Edit (${_idController.text})': 'Datos General Paciente New', 
                              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                  leading: ButtonBack(),
                  ), 
    
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.save_as_outlined, color: Colors.lightBlue),
                    title: const Text('Guardar'),
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() {
                        _isGrabado = false;
                      });
                      if (_idController.text=='0') {
                        _guardarDatos();
                      } else {
                        _updateDatos();
                      }
                      
                      if (_idController.text!='0' && _isGrabado) {
                        ToastMSG.showInfo(context, 'Paciente Guardado Correctamente...Código Interno ${_idController.text}', 2);
                      } 
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.clear_all_sharp, color: Colors.lightBlue),
                    title: const Text('Limpiar'),
                    onTap: () {
                      Navigator.pop(context);
                      ToastMSG.showInfo(context, 'Limpieza En Construcción', 2);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.arrow_circle_left_outlined, color: Colors.lightBlue),
                    title: const Text('Volver'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      child: const Icon(Icons.menu),
    ),
    floatingActionButtonLocation: MediaQuery.of(context).size.width >1200 ? FloatingActionButtonLocation.centerDocked : FloatingActionButtonLocation.endDocked,

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
                      xl: 3,
                      lg: 3,
                      md: 4,
                      sm: 5,
                      xs: 5,
                      child: dropdownTipoDocField(context: context, valueTipoDoc: _valueTipoDoc, tipoDocList: _tipoDoc),  
                    ),
                    ResponsiveGridCol(
                      xl: 5,
                      lg: 5,
                      md: 8,
                      sm: 7,
                      xs: 7,
                      child: cedulaPacienteField(context, cedulaController),  
                    ),
                  ],
                ),
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                      xl: 4,
                      lg: 4,
                      md: 6,
                      sm: 12,
                      xs: 12,
                      child: apellidosPacienteField(context, apellidosController), 
                    ),
                    ResponsiveGridCol(
                      xl: 4,
                      lg: 4,
                      md: 6,
                      sm: 12,
                      xs: 12,
                      child: nombresPacienteField(context, nombresController), 
                    ),
                  ]
                ),
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                      xl: 4,
                      lg: 4,
                      md: 6,
                      sm: 12,
                      xs: 12,
                      child: direccionPacienteField(context, direccionController),  
                    ),
                    ResponsiveGridCol(
                      xl: 4,
                      lg: 4,
                      md: 6,
                      sm: 12,
                      xs: 12,
                      child: correoPacienteField(context, correoController), 
                    ),
                  ]
                ),
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                        lg: 3,
                        xl: 3,
                        md: 4,
                        sm: 5,
                        xs: 5,
                        child: dropdownGeneroField(context: context, valueGenero: _valueGenero, generoList: _genero) , //_dropdownButtonGenero()
                    ),
                    ResponsiveGridCol(
                        lg: 3,
                        xl: 3,
                        md: 6,
                        sm: 5,
                        xs: 5,
                        child: fechaNacimientoField(context: context, fechaNacimientoController: fechaNacimientoController) , //_fechaNacimiento(context)
                    ),
                    ResponsiveGridCol(
                        lg: 2,
                        xl: 2,
                        md: 2,
                        sm: 2,
                        xs: 2,
                        child: edadPacienteField(context, edadController) , //_edadPaciente()
                    ),
                  ],
                ),
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                      xl: 3,
                      lg: 3,
                      md: 4,
                      sm: 5,
                      xs: 5,
                      child: dropdownEstadoCivilField(context: context, valueEstadoCivil: _valueEstadoCivil, estadoCivilList: _estadoCivil) , 
                    ),
                    ResponsiveGridCol(
                      xl: 5,
                      lg: 5,
                      md: 8,
                      sm: 7,
                      xs: 7,
                      child: telefonoPacienteField(context, telefonosController) , 
                    ),
                  ]
                ),
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                      xl: 3,
                      lg: 3,
                      md: 4,
                      sm: 5,
                      xs: 5,
                      child: dropdownTipoSangreField(context: context, valueTipoSangre: _valueTipoSangre, tipoSangreList: _tipoSangre ), 
                    ),
                    ResponsiveGridCol(
                      xl: 5,
                      lg: 5,
                      md: 8,
                      sm: 7,
                      xs: 7,
                      child: ocupacionReferenciaField(context, ocupacionReferenciaController) , 
                    ),
                  ]
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  
}

// datos personales

Widget dropdownTipoDocField({required BuildContext context, required String? valueTipoDoc, required List<Map<String, String>> tipoDocList,}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: DropdownButtonFormField<String>(
      value: valueTipoDoc,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Tipo Doc',
        hintText: '-- Sin selección --',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        prefixIcon: esPantallaGrande(context) ? const Icon(Icons.document_scanner) : null,
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
      ),
      items: tipoDocList
          .map((item) => DropdownMenuItem<String>(
                value: item['codigo'],
                child: Text(item['descripcion'] ?? ''),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _valueTipoDoc = value;
          tipoDocController.text = value ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Seleccione un Tipo Documento';
        }
        return null;
      },
    ),
  );
}

Widget cedulaPacienteField(BuildContext context, TextEditingController cedulaController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: cedulaController,
      showCursor: true,
      maxLength: 10,
      keyboardType: tipoDocController.text=='1' ? TextInputType.number: TextInputType.text,
      decoration: InputDecoration(
        labelText: 'Id Documento',
        counterText: "",
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: const Icon(Icons.account_box_sharp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        suffixIcon: _idController.text=='0' ? null : IconButton(
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
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese una cédula';
        }
        if (tipoDocController.text=='1') {
          if (!validarCedulaEcuatoriana(value.toString().trim())) {
            return 'Cédula inválida';
          }
        }
        return null;
      },
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
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese Apellidos';
        }
        if (value.trim().length < 5) {
          return 'Debe tener al menos 5 caracteres';
        }
        if (!soloLetras(value.trim())) {
          return 'Solo letras permitidas';
        }
        return null;
      },
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
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese nombres';
        }
        if (value.trim().length < 5) {
          return 'Debe tener al menos 5 caracteres';
        }
        if (!soloLetras(value.trim())) {
          return 'Solo letras permitidas';
        }
        return null;
      },
      onChanged: (value) {
        // Puedes colocar lógica reactiva aquí si es necesario
      },
    ),
  );
}

Widget direccionPacienteField(BuildContext context, TextEditingController direccionController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: direccionController,
      showCursor: true,
      maxLength: 200,
      textCapitalization: TextCapitalization.sentences,
      inputFormatters: [UpperCaseTextFormatter()],
      keyboardType: TextInputType.streetAddress,
      decoration: InputDecoration(
        labelText: 'Dirección',
        counterText: "",
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: const Icon(Icons.home_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      textAlign: TextAlign.left,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese una dirección válida';
        }
        if (value.trim().length < 5) {
          return 'La dirección es muy corta';
        }
        return null;
      },
      onChanged: (value) {
        // Puedes aplicar lógica reactiva aquí si es necesario
      },
    ),
  );
}

Widget correoPacienteField(BuildContext context, TextEditingController correoController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: correoController,
      keyboardType: TextInputType.emailAddress,
      maxLength: 100,
      showCursor: true,
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        hintText: 'ejemplo@dominio.com',
        counterText: "",
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: const Icon(Icons.alternate_email),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      textAlign: TextAlign.left,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El correo es obligatorio';
        }
        if (!_emailRegex.hasMatch(value.trim())) {
          return 'Correo electrónico inválido';
        }
        return null;
      },
      onChanged: (value) {
        // Opcional: lógica en tiempo real
      },
    ),
  );
}

Widget dropdownGeneroField({required BuildContext context, required String? valueGenero, required List<Map<String, String>> generoList,}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: DropdownButtonFormField<String>(
      value: valueGenero,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Género',
        hintText: '-- Sin selección --',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        prefixIcon: const Icon(Icons.transgender),
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
      ),
      items: generoList
          .map((item) => DropdownMenuItem<String>(
                value: item['codigo'],
                child: Text(item['descripcion'] ?? ''),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _valueGenero = value;
          generoController.text = value ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Seleccione un género';
        }
        return null;
      },
    ),
  );
}

Widget telefonoPacienteField(BuildContext context, TextEditingController telefonosController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: telefonosController,
      showCursor: true,
      maxLength: 50,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,\-\s+]')), // solo números, comas, espacios y "+"
      ],
      decoration: InputDecoration(
        labelText: 'Teléfono(s)',
        counterText: "",
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: const Icon(Icons.phonelink_ring),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        hintText: 'Ej: 0991234567, 022345678',
      ),
      textAlign: TextAlign.left,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese al menos un número de teléfono';
        }
        if (value.length < 7) {
          return 'Número(s) de teléfono demasiado corto(s)';
        }
        return null;
      },
      onChanged: (value) {
        // Lógica adicional si se requiere
      },
    ),
  );
}

Widget fechaNacimientoField({required BuildContext context, required TextEditingController fechaNacimientoController,}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: fechaNacimientoController,
      readOnly: true,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: 'Fecha Nacimiento',
        hintText: 'Seleccione una fecha',
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: const Icon(Icons.cake_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Debe ingresar una fecha válida';
        }
        return null;
      },
      onTap: () async {
        FocusScope.of(context).unfocus(); // Oculta el teclado si abierto
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(), //.subtract(const Duration(days: 365 * 18)), // por defecto, 18 años atrás
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          helpText: 'Seleccione fecha de nacimiento',
        );

        if (pickedDate != null) {
          String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
          fechaNacimientoController.text = formattedDate;
          actualizarEdad(pickedDate, edadController);
        }
      },
    ),
  );
}

Widget edadPacienteField(BuildContext context, TextEditingController edadController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: edadController,
      readOnly: true,
      showCursor: false,
      enabled: false, // visualmente deshabilitado pero legible
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: 'Edad',
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: MediaQuery.of(context).size.width>1024 ? const Icon(Icons.calendar_today) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Theme.of(context).disabledColor),
        ),
        filled: true,
        fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.05),
      ),
      style: const TextStyle(fontWeight: FontWeight.bold),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    ),
  );
}

Widget dropdownEstadoCivilField({required BuildContext context, required String? valueEstadoCivil, required List<Map<String, String>> estadoCivilList,}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: DropdownButtonFormField<String>(
      value: valueEstadoCivil,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Estado Civil',
        hintText: '-- Sin selección --',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        prefixIcon: esPantallaGrande(context) ? const Icon(Icons.document_scanner) : null,
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
      ),
      items: estadoCivilList
          .map((item) => DropdownMenuItem<String>(
                value: item['codigo'],
                child: Text(item['descripcion'] ?? ''),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _valueEstadoCivil = value;
          estadoCivilController.text = value ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Seleccione un Estado Civil';
        }
        return null;
      },
    ),
  );
}

Widget dropdownTipoSangreField({required BuildContext context, required String? valueTipoSangre, required List<Map<String, String>> tipoSangreList,}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: DropdownButtonFormField<String>(
      value: valueTipoSangre,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Tipo Sangre',
        hintText: '-- Sin selección --',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        prefixIcon: esPantallaGrande(context) ? const Icon(Icons.bloodtype_outlined) : null,
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
      ),
      items: tipoSangreList
          .map((item) => DropdownMenuItem<String>(
                value: item['codigo'],
                child: Text(item['descripcion'] ?? ''),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _valueTipoSangre = value;
          tipoSangreController.text = value ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Seleccione un Tipo Sangre';
        }
        return null;
      },
    ),
  );
}

Widget ocupacionReferenciaField(BuildContext context, TextEditingController ocupacionReferenciaController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: ocupacionReferenciaController,
      showCursor: true,
      maxLength: 200,
      textCapitalization: TextCapitalization.sentences,
      inputFormatters: [UpperCaseTextFormatter()],
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: 'Ocupación/Ref.:',
        counterText: "",
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: const Icon(Icons.work_history_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      textAlign: TextAlign.left,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese una ocupación';
        }
        if (value.trim().length < 5) {
          return 'La descripción de la ocupación es muy corta';
        }
        return null;
      },
      onChanged: (value) {
        // Puedes aplicar lógica reactiva aquí si es necesario
      },
    ),
  );
}


}

