import 'package:flutter/material.dart';

class OdontologiaMenu extends StatelessWidget {
  final Function(String) onOptionSelected;
  final bool isHorizontal;

  const OdontologiaMenu({
    super.key,
    required this.onOptionSelected,
    this.isHorizontal = false,
  });

  // Menú organizado por categorías
  final menuCategories = const [
    {
      'category': 'Gestión de Pacientes',
      'color': Color(0xFF4CAF50),
      'icon': Icons.people,
      'items': [
        {'icon': Icons.person_search, 'title': 'Pacientes', 'subtitle': 'Lista y búsqueda'},
        {'icon': Icons.person_add, 'title': 'Paciente', 'subtitle': 'Nuevo paciente'},
        {'icon': Icons.medical_services, 'title': 'Historia Clinica', 'subtitle': 'Registros médicos'},
        {'icon': Icons.cake, 'title': 'Cumpleaños', 'subtitle': 'Pacientes del mes'},
      ]
    },
    {
      'category': 'Citas y Agendas',
      'color': Color(0xFF2196F3),
      'icon': Icons.calendar_month,
      'items': [
        {'icon': Icons.event_available, 'title': 'Citas', 'subtitle': 'Ver citas'},
        {'icon': Icons.schedule, 'title': 'Agendar Citas', 'subtitle': 'Nueva cita'},
      ]
    },
    {
      'category': 'Inventario',
      'color': Color(0xFFFF9800),
      'icon': Icons.inventory,
      'items': [
        {'icon': Icons.business, 'title': 'Proveedores', 'subtitle': 'Gestión proveedores'},
        {'icon': Icons.inventory_2, 'title': 'Suministros', 'subtitle': 'Maestro de suministros'},
        {'icon': Icons.input, 'title': 'Transacciones Ingreso', 'subtitle': 'Entrada de productos'},
        {'icon': Icons.output, 'title': 'Transacciones Egreso', 'subtitle': 'Salida de productos'},
      ]
    },
    {
      'category': 'Tratamientos',
      'color': Color(0xFF9C27B0),
      'icon': Icons.healing,
      'items': [
        {'icon': Icons.medical_services, 'title': 'Tratamientos', 'subtitle': 'Gestión tratamientos'},
      ]
    },
    {
      'category': 'Sistema',
      'color': Color(0xFF607D8B),
      'icon': Icons.settings,
      'items': [
        {'icon': Icons.settings, 'title': 'Configuración', 'subtitle': 'Ajustes del sistema'},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return isHorizontal
        ? _buildHorizontalMenu(context)
        : _buildVerticalMenu(context);
  }

  Widget _buildHorizontalMenu(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: menuCategories.expand((category) => 
          category['items'] as List<Map<String, dynamic>>
        ).map((item) => _buildHorizontalCard(context, item)).toList(),
      ),
    );
  }

  Widget _buildVerticalMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context),
          ...menuCategories.map((category) => _buildCategorySection(context, category)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Clínica Odontológica',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Sistema de Gestión',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, Map<String, dynamic> category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category['color'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category['icon'],
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category['category'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        ...(category['items'] as List<Map<String, dynamic>>).map(
          (item) => _buildMenuItem(context, item, category['color']),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, Map<String, dynamic> item, Color categoryColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            onOptionSelected(item['title']);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item['icon'],
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onOptionSelected(item['title']),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item['icon'],
                    color: Colors.blue.shade600,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item['title'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['subtitle'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

