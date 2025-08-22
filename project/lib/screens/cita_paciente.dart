import 'dart:convert';
import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';

import 'package:mailer/mailer.dart';
import 'package:odontologo/object/email_model.dart';
import 'package:odontologo/object/patient.dart';
import 'package:odontologo/object/appointment.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:odontologo/services/mayusculas.dart';
import 'package:odontologo/services/send_email.dart';
import 'package:odontologo/widgets/toast_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:odontologo/services/http_interceptor.dart';
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

  // Controlador para el status de la cita
  String _selectedStatus = 'pending';

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

  // Opciones de status para las citas
  final List<Map<String, String>> _statusOptions = [
    {'value': 'pending', 'label': 'Pendiente'},
    {'value': 'completed', 'label': 'Completada'},
    {'value': 'cancelled', 'label': 'Cancelada'},
  ];

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
  _selectedStatus = 'pending';
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
    // ✅ Formulario válido, guardar cita
    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: 'Procesando Cita...');

    try {
      // Validar que los campos requeridos estén completos
      if (_idController.text.isEmpty || 
          _valuedentists == '0' || 
          _valueoffices == '0' || 
          appointmentTimeController.text.isEmpty || 
          reasonController.text.isEmpty) {
        throw Exception('Por favor complete todos los campos requeridos');
      }

      CreateAppointment appointment = CreateAppointment(
        patientId: int.parse(_idController.text),
        dentistId: int.parse(_valuedentists!),
        officeId: int.parse(_valueoffices!),
        appointmentTime: appointmentTimeController.text,
        status: _selectedStatus,
        reason: reasonController.text,
      );

      final res = await HttpInterceptor.post(
        '/api/appointments', 
        headers: {},
        body: jsonEncode(appointment.toJson())
      );
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final jsonData = jsonDecode(res.body);
        Appointment savedAppointment;
        
        // Manejar tanto array como objeto único
        if (jsonData is List) {
          savedAppointment = Appointment.fromJson(jsonData.first);
        } else {
          savedAppointment = Appointment.fromJson(jsonData);
        }

        setState(() {
          id = savedAppointment.id ?? 0;
          _isGrabado = true;
        });
        
        await _enviarEmail();
        
        if (mounted) {
          ToastMSG.showSuccess(context, 'Cita guardada exitosamente', 3);
        }
      }
      pr.close();
    } on Exception catch (e) {
      pr.close();
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error',
          desc: e.toString(),
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  } else {
    // ❌ Formulario inválido, mostrar error
    ToastMSG.showError(context, 'Por favor, complete el formulario correctamente', 2);
  }
}

void _updateDatos() async {
  if (_formKey.currentState?.validate() ?? false) {
    // ✅ Formulario válido, actualizar cita
    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: 'Procesando Actualización...');

    try {
      // Validar que los campos requeridos estén completos
      if (_idController.text.isEmpty || 
          _valuedentists == '0' || 
          _valueoffices == '0' || 
          appointmentTimeController.text.isEmpty || 
          reasonController.text.isEmpty) {
        throw Exception('Por favor complete todos los campos requeridos');
      }

      Appointment appointment = Appointment(
        id: id,
        patientId: int.parse(_idController.text),
        dentistId: int.parse(_valuedentists!),
        officeId: int.parse(_valueoffices!),
        appointmentTime: appointmentTimeController.text,
        status: _selectedStatus,
        reason: reasonController.text,
      );

      final res = await HttpInterceptor.put(
        '/api/appointments/$id', 
        headers: {},
        body: jsonEncode(appointment.toJson())
      );
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final jsonData = jsonDecode(res.body);
        Appointment updatedAppointment;
        
        // Manejar tanto array como objeto único
        if (jsonData is List) {
          updatedAppointment = Appointment.fromJson(jsonData.first);
        } else {
          updatedAppointment = Appointment.fromJson(jsonData);
        }

        setState(() {
          reasonController.text = updatedAppointment.reason;
          _isGrabado = true;
        });
        
        await _enviarEmail();
        
        if (mounted) {
          ToastMSG.showSuccess(context, 'Cita actualizada exitosamente', 3);
        }
      }
      pr.close();
    } on Exception catch (e) {
      pr.close();
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error',
          desc: e.toString(),
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  } else {
    // ❌ Formulario inválido, mostrar error
    ToastMSG.showError(context, 'Por favor, complete el formulario correctamente', 2);
  }
}

Future<void> _enviarEmail() async {
  if (correoController.text.toString().isEmpty) {
    ToastMSG.showInfo(context, 'No Hay Correo Definido...', 2);
    return;
  }

  final emailData = EmailModel(
    from: Address('tu_correo@gmail.com', 'Tu Nombre'),
    recipients: [correoController.text],
    ccRecipients: [''],
    bccRecipients: [''],
    subject: 'Correo desde Flutter',
    text: 'Este es el contenido en texto plano.',
    html: '<h2>Hola desde Flutter</h2><p>Este es el cuerpo en HTML.</p>',
    attachments: [File('/ruta/a/archivo.pdf')],
  );

  await sendEmail(emailData);

}

Future<void> _cargarDatosIni() async {
  List<Map<String, String>> offices =  [];
  List<Map<String, String>> dentists = [];
  try {
    // offices
    final res0 = await HttpInterceptor.get('/api/offices', headers: {});
    
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
    final res2 = await HttpInterceptor.get('/api/specialtyDentists', headers: {});

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

Future<void> _cargarDatos(int id, String cedula) async {
  ProgressDialog pr = ProgressDialog(context: context);
  pr.show(max: 600, msg: 'Procesando Consulta...');

  String url = '/api/patients/id/$id';
  if (cedula.isNotEmpty) {  
    url = '/api/patients/document/$cedula';
  }

  try {
    final res = await HttpInterceptor.get(url, headers: {});

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
        nombresController.text = patient.name;
        apellidosController.text = patient.lastName;
        telefonoController.text = patient.phone;
        correoController.text = patient.email; 

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
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.lightBlue),
                    title: const Text('Limpiar'),
                    onTap: () {
                      Navigator.pop(context);
                      _limpiarDet();
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
                          child: statusField(context),
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
            //_cargarDatos(_idController.text as int);
            _cargarDatos(_idController.text as int, cedulaController.text);
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
          _valueoffices = value;
          officesController.text = value ?? '';
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

Widget statusField(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    child: DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Estado de la Cita',
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: const Icon(Icons.info_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      items: _statusOptions.map((status) {
        return DropdownMenuItem<String>(
          value: status['value'],
          child: Row(
            children: [
              Icon(
                _getStatusIcon(status['value']!),
                color: _getStatusColor(status['value']!),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(status['label']!),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedStatus = newValue;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Seleccione un estado';
        }
        return null;
      },
    ),
  );
}

IconData _getStatusIcon(String status) {
  switch (status) {
    case 'pending':
      return Icons.schedule;
    case 'completed':
      return Icons.check_circle;
    case 'cancelled':
      return Icons.cancel;
    default:
      return Icons.help;
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'completed':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}


}

