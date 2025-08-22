import 'package:flutter/material.dart';
import 'package:odontologo/widgets/main_menu.dart';
import 'package:odontologo/screens/screens_export.dart';
import 'package:odontologo/services/auth_service.dart';


class AppRoutes {
  static const String initialRoute = '/';
  static const String login = '/login';
  static const String menu = '/menu';
  static const String pacientes = '/pacientes';
  static const String paciente = '/paciente';
  static const String historiaClinica = '/historia';
  static const String citas = '/citas';
  static const String agendarcitas = '/agendarcitas';
  static const String tratamientos = '/tratamientos';
  static const String facturacion = '/facturacion';
  static const String inventario = '/inventario';
  static const String configuracion = '/configuracion';
  static const String cumpleanos = '/cumpleanos';
  static const String proveedores = '/proveedores';
  static const String proveedor = '/proveedor';
  static const String suministros = '/suministros';
  static const String suministro = '/suministro';
  static const String transaccionesIngreso = '/transacciones_ingreso';
  static const String transaccionIngreso = '/transaccion_ingreso';
  static const String transaccionesEgreso = '/transacciones_egreso';
  static const String transaccionEgreso = '/transaccion_egreso';

  static Map<String, WidgetBuilder> routes = {
    initialRoute: (context) => const AuthWrapper(),
    login: (context) => const MyHomePage(title: 'Clínica Odontológica'),
    menu: (context) => const HomeScreen(),
    pacientes: (context) => const Pacientes(),
    paciente: (context) => const Paciente(),
    historiaClinica: (context) => const HistoriaClinica(),
    citas: (context) => const CitaPaciente(),
    agendarcitas: (context) => const AgendarCitas(),
    tratamientos: (context) => const Paciente(),
    facturacion: (context) => const Paciente(),
    inventario: (context) => const Paciente(),
    configuracion: (context) => const Paciente(),
    cumpleanos: (context) => const CumpleanosPacientes(),
    proveedores: (context) => const Proveedores(),
    proveedor: (context) => const Proveedor(),
    suministros: (context) => const Suministros(),
    suministro: (context) => const Suministro(),
    transaccionesIngreso: (context) => const TransaccionesIngreso(),
    transaccionIngreso: (context) => const TransaccionIngreso(),
    transaccionesEgreso: (context) => const TransaccionesEgreso(),
    transaccionEgreso: (context) => const TransaccionEgreso(),
  };

  // Middleware para verificar autenticación
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Rutas que no requieren autenticación
    final publicRoutes = [login, initialRoute];
    
    if (publicRoutes.contains(settings.name)) {
      return MaterialPageRoute(
        builder: (context) => routes[settings.name]!(context),
        settings: settings,
      );
    }

    // Rutas que requieren autenticación
    return MaterialPageRoute(
      builder: (context) => AuthGuard(
        child: routes[settings.name] ?? routes[menu]!,
        settings: settings,
      ),
      settings: settings,
    );
  }
}

// Widget wrapper para manejar el estado de autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          return const HomeScreen();
        } else {
          return const MyHomePage(title: 'Clínica Odontológica');
        }
      },
    );
  }
}

// Guard para proteger rutas autenticadas
class AuthGuard extends StatelessWidget {
  final Widget Function(BuildContext) child;
  final RouteSettings settings;

  const AuthGuard({
    super.key,
    required this.child,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          return child(context);
        } else {
          // Redirigir al login si no está autenticado
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          });
          return const Scaffold(
            body: Center(
              child: Text('Redirigiendo al login...'),
            ),
          );
        }
      },
    );
  }
}
