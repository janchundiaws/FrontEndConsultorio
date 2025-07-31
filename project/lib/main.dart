
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odontologo/widgets/main_menu.dart';
import 'variables_globales.dart';
import 'widgets/toast_msg.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clínica Odontológica',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue), 
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Clínica Odontológica'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isAuthenticating = false;
  bool _obscureText = true;
  bool saveCredentials = true;

  TextEditingController user = TextEditingController();
  TextEditingController password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      user.text = prefs.getString('username') ?? "";
      password.text = prefs.getString('password') ?? "";
      token = prefs.getString('token') ?? "";
      fechaValidaToken = prefs.getString('fechaValidaToken') ?? "";
      tenantId = prefs.getString('tenantId') ?? "";
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (saveCredentials) {
      await prefs.setString('username', user.text);
      await prefs.setString('password', password.text);
      await prefs.setString('token', token);
      await prefs.setString('fechaValidaToken', fechaValidaToken);
      await prefs.setString('tenantId', tenantId);
    } else {
      await prefs.setString('username', '');
      await prefs.setString('password', '');
      await prefs.setString('token', '');
      await prefs.setString('fechaValidaToken', '');
      await prefs.setString('tenantId', '');
    }


  }

  void _togglePasswordStatus() {
      setState(() {
        _obscureText = !_obscureText;
      });
    }

  void _onRememberMeChanged(bool newValue) => setState(() {
      saveCredentials = newValue;
    });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft, // Comienza desde el centro izquierdo
                      end: Alignment.centerRight, // Termina en el centro derecho
                      colors: [
                        Colors.blue[600]!, // Un tono de azul oscuro para la mitad izquierda
                        Colors.blue[50]!, // Un tono de azul más claro hacia la mitad
                        Colors.blue[50]!, // Un azul muy claro justo antes de la transición
                        Colors.blue[50]!, // Repetir el azul muy claro para crear un punto de transición definido
                        Colors.white, // Finalmente, color blanco para la mitad derecha
                      ],
                      stops: const [0.0, 0.49, 0.5, 0.5, 1.0], // Puntos de parada para definir la transición exacta en la mitad
                    ),
                  ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Container(
                    padding: EdgeInsets.only(top:MediaQuery.of(context).size.height * 0.08),
                    child: ResponsiveGridRow(
                      children: [
                        ResponsiveGridCol(
                          xl: 1,                            
                          lg: 1,
                          md: 2,
                          sm: 1,
                          xs: 0,
                          child: const Text(""),
                        ),
                        ResponsiveGridCol(
                            xl: kIsWeb?6:0,                            
                            lg: kIsWeb?4:0,
                            md: 0,
                            sm: 0,
                            xs: kIsWeb?0:0,
                            child: Container(
                              width: double.infinity,
                              height: 600,
                              padding: const EdgeInsets.all(20),
                              color: Colors.white,
                              child: Column(
                                  children: [
                                    const SizedBox(height: 24,),
                                    const Text("BIENVENIDOS" , style:TextStyle(fontWeight: FontWeight.bold,fontSize: 30,color: Color.fromARGB(255, 230, 97, 19)) ),
                                    SizedBox(
                                      width: 300,
                                      child: Lottie.asset('assets/json/diente-limpio.json'),
                                    ),
                                    const SizedBox(height: 80,),
                                    Text('Copyright © ${DateTime.now().year} - Peob (SI)', style:const TextStyle(fontWeight: FontWeight.bold,fontSize: 16) ),
                                  ],
                                ),
                            )
                          ),
                        ResponsiveGridCol(
                          xl: 4,                          
                          lg: 6,
                          md: 8,
                          sm: 10,
                          xs: kIsWeb?12:12,
                          child: Container(
                            height: 600,
                            color: Colors.white,
                            child: columnLogin(context)
                          )
                        ),
                        ResponsiveGridCol(
                          xl: 1,                            
                          lg: 1,
                          md: 2,
                          sm: 1,
                          xs: 0,
                          child: const Text(""),
                        ),                        
                      ]
                    )
                  )
                )
              ],
            ),
          ),
      )
    );
  }

  //scaffold del login
  Padding columnLogin(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Lottie.asset('assets/json/diente-limpio.json'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(controller: user,
                decoration: const InputDecoration(
                labelText: 'Usuario',
                labelStyle: TextStyle(color: Colors.grey),
                icon: Icon(Icons.supervised_user_circle_sharp),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)),),
                ),
                textAlign: TextAlign.center,
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(controller: password,
                decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.grey),
                      icon: const Icon(Icons.password_rounded),
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)),),
                        suffixIcon: IconButton(
                                  icon:Icon(_obscureText ? Icons.visibility:Icons.visibility_off,),
                                  onPressed: _togglePasswordStatus,
                                  color: Colors.blueGrey,
                                ), 
                      ),

                textAlign: TextAlign.center,
                obscureText: _obscureText,
                obscuringCharacter: '*',
                onFieldSubmitted:_isAuthenticating ? null : (value) async{
                  _initLogin();
                }
              ),
        ),
          MaterialButton(
            shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(10)),
            disabledColor: Colors.grey,
            elevation: 0,
            color: Colors.blueGrey,
            onPressed: _isAuthenticating ? null : () async {
              _initLogin();  
            },
            child: SizedBox(
              width: double.infinity,
              child: Text(_isAuthenticating ? 'Validando': 'Ingresar',
              style: const TextStyle(
                color: Colors.white),
                textAlign:TextAlign.center,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Checkbox(
                  value: saveCredentials, 
                  onChanged: (value) {
                    _onRememberMeChanged(value!);
                  }
                  ),
              GestureDetector(
                onTap: () {
                  _onRememberMeChanged(!saveCredentials);
                },
                child: const Text('Recuerdame', style: TextStyle(fontWeight: FontWeight.bold),)
                ),
            ],
          ),
         ],
      ),
    );
  }

  Future<void> _initLogin()async{
    if (user.text.isEmpty || password.text.isEmpty) {
        Alert(
          context: context,
          type: AlertType.error,
          desc: 'Ingrese Usuario/Password...',
        ).show();
    } else {                          
      setState(() {
        _isAuthenticating = true;
        usuario = user.text;
        clave = password.text;
        token = '';
        userValido = '0';
      });
      await _obtenerToken(context); // obtener token
      setState(() {
        _isAuthenticating = false;
      });
      //print('userValido $userValido');
      if (userValido == '1') {
        // ignore: use_build_context_synchronously
        ToastMSG.showInfo(context,'Guardando Credenciales',2);
        _saveCredentials();
        // ignore: use_build_context_synchronously
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyAppMenu()));
      } else {
        // ignore: use_build_context_synchronously
        Alert(
          // ignore: use_build_context_synchronously
          context: context,
          type: AlertType.error,
          desc: 'El usuario $usuario es invalido...',
        ).show();
      }
    }
  }

  Future<void> _obtenerToken(BuildContext context) async {
    try {


      var request = http.Request('POST', Uri.parse('$baseUrl/api/login'));
      request.body = json.encode({
        "correo": usuario, 
        "password": clave 
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseBody);
        if (context.mounted) {
          setState(() {
            token = jsonData["token"]; 
            userValido = '1';
          });
        }
      }
      else {
        if (context.mounted) {
          setState(() {
            userValido = '0';
          });
        }        
        if (response.statusCode < 200 || response.statusCode >= 300) {
          Alert(
          // ignore: use_build_context_synchronously
          context: context,
          type: AlertType.warning,
          title: "Advertencia",
          desc: "Estado de conección: ${response.statusCode}",
          buttons: [DialogButton(child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 18),), onPressed: () => Navigator.pop(context)), ],
          ).show();
        }
      }
    
    } on Exception catch (e) {
      if (context.mounted) {
        ToastMSG.showError(context, '❌ Error: $e', 2);
      } else {
        // ignore: use_build_context_synchronously
        ToastMSG.showError(context, '⚠️ Error fuera de contexto: $e', 2);
        //print('⚠️ Error fuera de contexto: $e');
      }      
    }
  }



}
