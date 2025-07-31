import 'dart:convert';
import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:expandable_fab_lite/expandable_fab_lite.dart';
import 'package:odontologo/object/patient.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:odontologo/services/mayusculas.dart';
import 'package:odontologo/variables_globales.dart';
import 'package:odontologo/widgets/toast_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:http/http.dart' as http;
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

class CitaPaciente extends StatefulWidget {
  const CitaPaciente({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CitaPacienteScreen createState() => _CitaPacienteScreen();
}

class _CitaPacienteScreen extends State<CitaPaciente>{

  final TextEditingController _idController = TextEditingController();
  TextEditingController cedulaController = TextEditingController();
  TextEditingController nombresController = TextEditingController();
  TextEditingController apellidosController = TextEditingController();
  TextEditingController telefonoController = TextEditingController();
  TextEditingController correoController = TextEditingController();

  TextEditingController dentistsController =TextEditingController();
  TextEditingController officesController =TextEditingController();
  TextEditingController appointmentTimeController =TextEditingController();
  TextEditingController reasonController =TextEditingController();

  int id = 0;
  int unavez = 0;
  bool isReadOnly = false;
  bool _isGrabado = false;
  bool _isLoading = true;

  // para validación del formulario
  final _formKey = GlobalKey<FormState>();

  String? fileName;
  String? extension;
  String? base64File;
  bool isUploading = false;

  String? _valuedentists='0';
  String? _valueoffices='0';

  final List<Map<String, String>> _dentists =  [];
  final List<Map<String, String>> _offices =  [];

@override
void initState() {
  _limpiarVar();

  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final int? idPatient = args['idPatient'];
    final String? documentId = args['documentId'];
    final String? nombres = args['name'];
    final String? apellidos = args['lastName'];
    final String? telefonos = args['telefonos'];
    final String? correo = args['correo'];

    setState(() {
      unavez = 1;
    });
    llamadas();

    if (idPatient != null) {
      // Actualiza el controlador del ID con el valor recibido
      setState(() {
        _idController.text = idPatient.toString();
        cedulaController.text = documentId.toString();
        nombresController.text = nombres.toString();
        apellidosController.text = apellidos.toString();
        telefonoController.text = telefonos.toString();
        correoController.text = correo.toString();     
      });

      //_cargarDatos(idPatient);
    }
  });
}

@override
void dispose() {
  _idController.dispose();
  cedulaController.dispose();
  nombresController.dispose();
  apellidosController.dispose();
  telefonoController.dispose();
  correoController.dispose();
  dentistsController.dispose();
  officesController.dispose();
  appointmentTimeController.dispose();
  reasonController.dispose();
  super.dispose();
}

void _limpiarVar() {
  _idController.text='';
  cedulaController.text='';
  nombresController.text = '';
  apellidosController.text = '';
  telefonoController.text = '';
  correoController.text = '';
  _limpiarDet();

  id = 0;
  isReadOnly = false;
  _isGrabado = false;
  //_isLoading = false;
  
}

void _limpiarDet() {
  dentistsController.text = '';
  officesController.text = '';
  appointmentTimeController.text = '';
  reasonController.text = '';

  _valuedentists='0';
  _valueoffices='0';
}

Future<void> llamadas() async {
  if (unavez == 0) {
    await _cargarDatosIni();
  }
}

bool soloLetras(String texto) {
  return RegExp(r"^[A-ZÑÁÉÍÓÚÜ\s]+$").hasMatch(texto.toUpperCase());
}

bool esPantallaGrande(BuildContext context) {
  return MediaQuery.of(context).size.width >= 600;
}

void _guardarDatos() async {
  if (_formKey.currentState?.validate() ?? false) {
    // ✅ Formulario válido, guardar datos
    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: 'Procesando Grabar...');

/*     CreatePatient objPatient = CreatePatient(
      documentId: cedulaController.text,
      name: nombresController.text,
      lastName: apellidosController.text,

      occupation: ocupacionReferenciaController.text
    ); */

    var headersList = map;
    final headers = {
      'Authorization': 'Bearer $token',
    };
    headersList.addAll(headers);

    var url = Uri.parse('$baseUrl/api/patients');

    try {
      final res = await http.post(url, headers: headersList); // , body: jsonEncode(objPatient)
      
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
/*     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor, complete el formulario')),
    ); */
  }
}

void _updateDatos() async {
  if (_formKey.currentState?.validate() ?? false) {
    // ✅ Formulario válido, guardar datos
    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: 'Procesando Actualización...');

/*     CreatePatient objPatient = CreatePatient(
      documentId: cedulaController.text,
      name: nombresController.text,
      lastName: apellidosController.text,
      occupation: ocupacionReferenciaController.text
    ); */

    var headersList = map;
    final headers = {
      'Authorization': 'Bearer $token',
    };
    headersList.addAll(headers);

    var url = Uri.parse('$baseUrl/api/patients/${_idController.text}');

    try {
      final res = await http.put(url, headers: headersList);  // , body: jsonEncode(objPatient)
      
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
/*     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor, complete el formulario')),
    ); */
  }
}

Future<void> _cargarDatosIni() async {
  var headersList = map;
  final headers = {
    'Authorization': 'Bearer $token',
  };
  headersList.addAll(headers);
  var url0 = Uri.parse('$baseUrl/api/offices');

  List<Map<String, String>> offices =  [];
  List<Map<String, String>> dentists = [];
  try {
    // offices
    final res0 = await http.get(url0, headers: headersList);
    
    if (res0.statusCode >= 200 && res0.statusCode < 300) {
      final jsonData0 = jsonDecode(res0.body);

      offices.add({'codigo': '0', 'descripcion': '-- Sin Selección --'});
      jsonData0.toList().forEach((element) {
        final id = element['id']?.toString() ?? '';
        final name = element['name']?.toString() ?? '';
        final location = element['location']?.toString() ?? '';

        offices.add({
          'codigo': id,
          'descripcion': '$name $location}'
        });
      });
    } 

    // Dentista Especialidad
    var url2 = Uri.parse('$baseUrl/api/specialtyDentists');
    final res2 = await http.get(url2, headers: headersList);

    if (res2.statusCode >= 200 && res2.statusCode < 300) {
      final jsonData2 = jsonDecode(res2.body);

      dentists.add({'codigo': '0', 'descripcion': '-- Sin Selección --'});
      dentists.addAll(
        (jsonData2 as List<dynamic>).map((e) {
          final id = e['id']?.toString() ?? '';
          final nombres = e['nombres']?.toString() ?? '';
          final especialidad = e['especialidad']?.toString() ?? '';

          return {
            'codigo': id,
            'descripcion': '$nombres $especialidad',
          };
        })
      );
    }  

    setState(() {
      _offices.addAll(offices);
      _dentists.addAll(dentists);
      _isLoading = false;
      unavez = 1;
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

  var headersList = map;
  final headers = {
    'Authorization': 'Bearer $token',
  };
  headersList.addAll(headers);
  var url = Uri.parse('$baseUrl/api/patients/$id');

  try {
    final res = await http.get(url, headers: headersList);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      Patient patient = Patient.fromJson(jsonDecode(res.body));
      
      setState(() {
        // actualiza campos de la pantalla con el codigo existente
        cedulaController.text = patient.documentId;
        apellidosController.text = patient.lastName;
        nombresController.text = patient.name;
        //observacionController.text = patient.occupation;

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

Future<void> launchMail(String toEmail) async {
  final Uri mailUri = Uri(
    scheme: 'mailto',
    path: toEmail,
    queryParameters: {
      'subject': 'Hola desde Flutter',
      'body': 'Este mensaje se genera desde tu app.'
    },
  );
  if (await canLaunchUrl(mailUri)) {
    await launchUrl(mailUri);
  } else {
    throw 'No se pudo abrir la app de correo';
  }
}

Future<void> sendWhatsAppWeb({
  required String phoneNumber, // sin '+' al inicio
  required String message,
}) async {
  try {
    final link = WhatsAppUnilink(
      phoneNumber: phoneNumber,
      text: message,
    );
    final uri = link.asUri();

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback manual a wa.me
      final fallback = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
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

void sendWhatsAppMessage({
  required String phoneNumber,
  required String message,
}) async {
  final encoded = Uri.encodeComponent(message);
  final uri = Platform.isIOS
      ? Uri.parse('https://wa.me/$phoneNumber?text=$encoded')
      : Uri.parse('whatsapp://send?phone=$phoneNumber&text=$encoded');

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'No se pudo lanzar WhatsApp: $uri';
  }
}

Future<void> launchWhatsApp() async {
  final link = WhatsAppUnilink(
    phoneNumber: '+593959203165',  // con código país, se limpia internamente
    text: 'Mensaje usando whatsapp_unilink',
  );

  final uri = link.asUri();
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'No se pudo abrir WhatsApp con $uri';
  }
}

@override
Widget build(BuildContext context) {
  if (_isLoading) {
    if(unavez==0) {
      setState(() {
        unavez = 1;
      });      
      _cargarDatosIni();
    }
    return Center(child: CircularProgressIndicator());
  }
  //final isSmallScreen = MediaQuery.of(context).size.width < 600;
  return Scaffold(
    appBar: AppBar(title: Text('Cita Paciente', 
                              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                  leading: ButtonBack(),
                  ), 
    floatingActionButton: ExpandableFab(
      fabMargin: 8,
      icon: Icon(Icons.menu),
      children: [
        ActionButton(
            icon: const Icon(Icons.save_as_outlined),
            color: Colors.lightBlue,
            onPressed: () async { 
              setState(() {
                _isGrabado = false;
              });
              if (_idController.text=='') {
                ToastMSG.showInfo(context, 'enviando mensaje (${_idController.text})', 2);
                sendWhatsAppWeb(phoneNumber: '+593959203165', message: 'Hola desde Flutter');
                _guardarDatos();
              } else {
                ToastMSG.showInfo(context, 'enviando mensaje (${_idController.text})', 2);
                sendWhatsAppWeb(phoneNumber: '+593959203165', message: 'Hola desde Flutter...');
                _updateDatos();
              }
              
              if (_idController.text!='0' && _isGrabado) {
                ToastMSG.showInfo(context, 'Cita de Paciente Guardado Correctamente...', 2);
              } 
            }),
        ActionButton(
            icon: const Icon(Icons.delete_forever),
            color: Colors.lightBlue,
            onPressed: (){ _limpiarDet(); }),
        ActionButton(
            icon: const Icon(Icons.arrow_circle_left_outlined),
            color: Colors.lightBlue,
            onPressed: (){ Navigator.pop(context); })
      ],
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
                      xl: 4,
                      lg: 4,
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
                      xl: 6,
                      lg: 6,
                      md: 6,
                      sm: 6,
                      xs: 6,
                      child: apellidosPacienteField(context, apellidosController), 
                    ),
                    ResponsiveGridCol(
                      xl: 6,
                      lg: 6,
                      md: 6,
                      sm: 6,
                      xs: 6,
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
                      sm: 6,
                      xs: 6,
                      child: telefonosPacienteField(context, telefonoController), 
                    ),
                    ResponsiveGridCol(
                      xl: 8,
                      lg: 8,
                      md: 6,
                      sm: 6,
                      xs: 6,
                      child: correoPacienteField(context, correoController), 
                    ),
                  ]
                  
                ),
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                      lg: 4,
                      xl: 4,
                      md: 6,
                      sm: 6,
                      xs: 6,
                      child: appointmentTimeField(context: context, appointmentTimeController: appointmentTimeController), 
                    ),
                    ResponsiveGridCol(
                      xl: 4,
                      lg: 4,
                      md: 6,
                      sm: 6,
                      xs: 6,
                      child: dropdowndentistsField(context: context, valuedentists: _valuedentists, dentistsList: _dentists) , 
                    ),
                    ResponsiveGridCol(
                      xl: 4,
                      lg: 4,
                      md: 6,
                      sm: 6,
                      xs: 6,
                      child: dropdownofficesField(context: context, valueoffices: _valueoffices, officesList: _offices) , 
                    ),
                  ]
                ),
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
                          child: reasonField(context, reasonController),
                        )
                    ),
                  ]
                ),
              ],
            ),
          ),
        ),
      ]
    ),

  );
}

// datos personales -- Cita Paciente

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

Widget telefonosPacienteField(BuildContext context, TextEditingController telefonoController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: telefonoController,
      showCursor: true,
      maxLength: 50,
      readOnly: true,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [UpperCaseTextFormatter()],
      decoration: InputDecoration(
        labelText: 'Teléfono(s)',
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

Widget correoPacienteField(BuildContext context, TextEditingController correoController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: correoController,
      showCursor: true,
      maxLength: 50,
      readOnly: true,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [UpperCaseTextFormatter()],
      decoration: InputDecoration(
        labelText: 'Email',
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

Widget dropdowndentistsField({required BuildContext context, required String? valuedentists, required List<Map<String, String>> dentistsList,}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: DropdownButtonFormField<String>(
      value: valuedentists,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Doctor(a)',
        hintText: '-- Sin selección --',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        prefixIcon: esPantallaGrande(context) ? const Icon(Icons.document_scanner) : null,
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
      ),
      items: dentistsList
          .map((item) => DropdownMenuItem<String>(
                value: item['codigo'],
                child: Text(item['descripcion'] ?? ''),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _valuedentists = value;
          dentistsController.text = value ?? '';
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

Widget dropdownofficesField({required BuildContext context, required String? valueoffices, required List<Map<String, String>> officesList,}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: DropdownButtonFormField<String>(
      value: valueoffices,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Local',
        hintText: '-- Sin selección --',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        prefixIcon: esPantallaGrande(context) ? const Icon(Icons.document_scanner) : null,
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
      ),
      items: officesList
          .map((item) => DropdownMenuItem<String>(
                value: item['codigo'],
                child: Text(item['descripcion'] ?? ''),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _valuedentists = value;
          dentistsController.text = value ?? '';
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

Widget appointmentTimeField({required BuildContext context, required TextEditingController appointmentTimeController,}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: appointmentTimeController,
      readOnly: true,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: 'Fecha/Hora Cita',
        hintText: 'Seleccione una fecha y hora',
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Debe ingresar una Fecha y Hora válida';
        }
        return null;
      },
      onTap: () async {
        FocusScope.of(context).unfocus(); // Cierra el teclado

        // Seleccionar fecha
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          helpText: 'Seleccione la fecha de la cita',
        );

        if (pickedDate != null) {
          // Seleccionar hora
          TimeOfDay? pickedTime = await showTimePicker(
            // ignore: use_build_context_synchronously
            context: context,
            initialTime: TimeOfDay.now(),
            helpText: 'Seleccione la hora de la cita',
          );

          if (pickedTime != null) {
            // Combinar fecha y hora
            final DateTime fullDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );

            // Formatear como string
            final formatted = "${fullDateTime.year.toString().padLeft(4, '0')}-"
                              "${fullDateTime.month.toString().padLeft(2, '0')}-"
                              "${fullDateTime.day.toString().padLeft(2, '0')} "
                              "${pickedTime.hour.toString().padLeft(2, '0')}:"
                              "${pickedTime.minute.toString().padLeft(2, '0')}";

            appointmentTimeController.text = formatted;
          }
        }
      },
    ),
  );
}

Widget reasonField(BuildContext context, TextEditingController reasonController) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: TextFormField(
      controller: reasonController,
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


}

