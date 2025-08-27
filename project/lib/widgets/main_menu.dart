import 'package:flutter/material.dart';
import 'package:odontologo/widgets/odontoligia_menu.dart';
import 'package:odontologo/routes.dart';

class MyAppMenu extends StatelessWidget {
  const MyAppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clínica Odontológica',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.menu,
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onMenuOptionSelected(BuildContext context, String option) {
    final routeMap = {
      'Pacientes': AppRoutes.pacientes,
      'Paciente': AppRoutes.paciente,
      'Historia Clinica': AppRoutes.historiaClinica,
      'Citas': AppRoutes.citas,
      'Agendar Citas': AppRoutes.agendarcitas,
      'Cumpleaños': AppRoutes.cumpleanos,
      'Proveedores': AppRoutes.proveedores,
      'Suministros': AppRoutes.suministros,
      'Transacciones Ingreso': AppRoutes.transaccionesIngreso,
      'Transacciones Egreso': AppRoutes.transaccionesEgreso,
      'Reporte Stock Suministros': AppRoutes.reporteStockSuministros,
      'Tratamientos': AppRoutes.tratamientos,
      'Facturación': AppRoutes.facturacion,
      'Inventario': AppRoutes.inventario,
      'Configuración': AppRoutes.configuracion,
    };

    final routeName = routeMap[option];

    if (routeName != null) {
      Navigator.pushNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth >= 1200;
        bool isMedium = constraints.maxWidth >= 800;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildAppBar(context),
          drawer: isWide ? null : _buildDrawer(context),
          body: Row(
            children: [
              if (isWide) _buildSidebar(context),
              Expanded(
                child: _buildMainContent(context, isWide, isMedium),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.teal.shade700,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.medical_services,
              color: Colors.teal.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Clínica Odontológica',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getCurrentTime(),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: OdontologiaMenu(
        onOptionSelected: (option) => _onMenuOptionSelected(context, option),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: OdontologiaMenu(
        onOptionSelected: (option) => _onMenuOptionSelected(context, option),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, bool isWide, bool isMedium) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 40 : 16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildWelcomeSection(context, isWide, isMedium),
              SizedBox(height: isWide ? 40 : 24),
              _buildQuickStats(context, isWide, isMedium),
              SizedBox(height: isWide ? 40 : 24),
              _buildQuickActions(context, isWide, isMedium),
              SizedBox(height: isWide ? 40 : 24), // Espacio adicional al final
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, bool isWide, bool isMedium) {
    return Container(
      padding: EdgeInsets.all(isWide ? 32 : (isMedium ? 20 : 16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade600,
            Colors.teal.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isWide || isMedium
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido al Sistema!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWide ? 28 : (isMedium ? 22 : 20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gestiona tu clínica odontológica de manera eficiente y profesional',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: isWide ? 16 : (isMedium ? 14 : 12),
                        ),
                      ),
                      SizedBox(height: isWide ? 24 : 16),
                      ElevatedButton.icon(
                        onPressed: () => _onMenuOptionSelected(context, 'Pacientes'),
                        icon: const Icon(Icons.person_search),
                        label: const Text('Ver Pacientes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.teal.shade700,
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 24 : 16,
                            vertical: isWide ? 12 : 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMedium)
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/Odontologia04.png',
                        height: 80,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Bienvenido al Sistema!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gestiona tu clínica odontológica de manera eficiente y profesional',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _onMenuOptionSelected(context, 'Pacientes'),
                  icon: const Icon(Icons.person_search, size: 18),
                  label: const Text('Ver Pacientes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickStats(BuildContext context, bool isWide, bool isMedium) {
    final stats = [
      {'icon': Icons.people, 'label': 'Pacientes', 'value': '150+', 'color': Colors.blue},
      {'icon': Icons.calendar_today, 'label': 'Citas Hoy', 'value': '8', 'color': Colors.green},
      {'icon': Icons.inventory, 'label': 'Productos', 'value': '45', 'color': Colors.orange},
      {'icon': Icons.business, 'label': 'Proveedores', 'value': '12', 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen Rápido',
          style: TextStyle(
            fontSize: isWide ? 24 : (isMedium ? 20 : 18),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: isWide ? 20 : (isMedium ? 16 : 12)),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : (isMedium ? 2 : 1),
            crossAxisSpacing: isWide ? 16 : (isMedium ? 12 : 8),
            mainAxisSpacing: isWide ? 16 : (isMedium ? 12 : 8),
            childAspectRatio: isWide ? 1.5 : (isMedium ? 2.0 : 2.2),
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _buildStatCard(stat, isWide, isMedium);
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isWide, bool isMedium) {
    return Container(
      padding: EdgeInsets.all(isWide ? 20 : (isMedium ? 16 : 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isWide ? 12 : (isMedium ? 10 : 8)),
            decoration: BoxDecoration(
              color: stat['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              stat['icon'],
              color: stat['color'],
              size: isWide ? 28 : (isMedium ? 24 : 20), //size: isWide ? 32 : (isMedium ? 28 : 24),
            ),
          ),
          SizedBox(height: isWide ? 10 : (isMedium ? 9 : 8)), //SizedBox(height: isWide ? 16 : (isMedium ? 12 : 8)),
          Text(
            stat['value'],
            style: TextStyle(
              fontSize: isWide ? 24 : (isMedium ? 20 : 18),
              fontWeight: FontWeight.bold,
              color: stat['color'],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat['label'],
            style: TextStyle(
              fontSize: isWide ? 11 : (isMedium ? 10 : 9),
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isWide, bool isMedium) {
    final actions = [
      {'icon': Icons.person_add, 'label': 'Nuevo Paciente', 'route': 'Paciente'},
      {'icon': Icons.schedule, 'label': 'Agendar Cita', 'route': 'Agendar Citas'},
      {'icon': Icons.inventory_2, 'label': 'Gestionar Inventario', 'route': 'Suministros'},
      {'icon': Icons.business, 'label': 'Proveedores', 'route': 'Proveedores'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: isWide ? 24 : (isMedium ? 20 : 18),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: isWide ? 20 : (isMedium ? 16 : 12)),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : (isMedium ? 2 : 1),
            crossAxisSpacing: isWide ? 16 : (isMedium ? 12 : 8),
            mainAxisSpacing: isWide ? 16 : (isMedium ? 12 : 8),
            childAspectRatio: isWide ? 1.2 : (isMedium ? 1.5 : 1.6),
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(action, isWide, isMedium);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, bool isWide, bool isMedium) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onMenuOptionSelected(context, action['route']),
        child: Container(
          padding: EdgeInsets.all(isWide ? 20 : (isMedium ? 16 : 12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isWide ? 16 : (isMedium ? 12 : 8)),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action['icon'],
                  color: Colors.teal.shade700,
                  size: isWide ? 32 : (isMedium ? 28 : 24),
                ),
              ),
              SizedBox(height: isWide ? 16 : (isMedium ? 12 : 8)),
              Text(
                action['label'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWide ? 16 : (isMedium ? 14 : 12),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

