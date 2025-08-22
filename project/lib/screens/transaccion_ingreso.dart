/* Autor: Pio enrique Olvera Briones
   Fecha: 07/08/2025
   Descripción: pantalla para crear/editar transacciones de ingreso de insumos
*/

import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:button_navigation_bar/button_navigation_bar.dart';
import 'package:odontologo/object/incoming_transaction.dart';
import 'package:odontologo/object/supplier.dart';
import 'package:odontologo/object/master_supply.dart';
import 'package:odontologo/object/transaction_type.dart';
import 'package:odontologo/services/incoming_transaction_service.dart';
import 'package:odontologo/services/supplier_service.dart';
import 'package:odontologo/services/master_supply_service.dart';
import 'package:odontologo/services/settings_service.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:odontologo/widgets/connection_status.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:intl/intl.dart';
import 'package:odontologo/services/mayusculas.dart';
import 'package:pluto_grid/pluto_grid.dart';

class TransaccionIngreso extends StatefulWidget {
  const TransaccionIngreso({super.key});

  @override
  State<TransaccionIngreso> createState() => _TransaccionIngresoState();
}

class _TransaccionIngresoState extends State<TransaccionIngreso> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers para la cabecera
  final _transactionNumberController = TextEditingController();
  final _transactionDateController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _subtotalController = TextEditingController();
  final _taxAmountController = TextEditingController();
  final _totalController = TextEditingController();
  final _notesController = TextEditingController();

  // Dropdowns y selecciones
  List<Supplier> _suppliers = [];
  List<MasterSupply> _supplies = [];
  Supplier? _selectedSupplier;
  String _selectedTransactionType = 'PURCHASE';
  String _selectedStatus = 'PENDING';

  // Lista de detalles
  final List<IncomingDetailForm> _details = [];
  PlutoGridStateManager? stateManager;
  List<PlutoColumn> columns = [];
  final List _lisDocumentDetails = [];
  
  // Variables de control
  int? _transactionId;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isLoadingDropdowns = false;

  // Opciones para dropdowns
  List<TransactionType> _transactionTypes = [];
  List<StatusOption> _statusOptions = [];

  @override
  void initState() {
    super.initState();
    //print('🚀 TransaccionIngreso inicializando...');
    
    columns = _columnsRender();

    // Usar un delay para asegurar que el contexto esté completamente disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //print('📱 Post frame callback ejecutado, iniciando carga...');
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    //print('🔄 Iniciando inicialización de datos...');
    
    // Verificar que el contexto esté disponible
    if (!mounted) {
      //print('⚠️ Contexto no disponible, abortando inicialización');
      return;
    }
    
    try {
      // Verificar conectividad
      final isConnected = await _checkConnectivity();
      if (!isConnected) {
        //print('⚠️ Sin conectividad, cargando datos de fallback');
        _loadFallbackData();
        return;
      }
      
      await _loadInitialData();
      //print('✅ Inicialización completada exitosamente');
    } catch (e, stackTrace) {
      //print('❌ Error durante inicialización: $e');
      print('📚 Stack trace: $stackTrace');
      
      //print('🔄 Intentando cargar datos de fallback...');
      _loadFallbackData();
      
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.warning,
          title: 'Modo Offline',
          desc: 'No se pudo conectar con los servicios. Se han cargado datos por defecto.\n\nError: $e',
          btnOkText: 'Continuar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  @override
  void dispose() {
    _transactionNumberController.dispose();
    _transactionDateController.dispose();
    _invoiceNumberController.dispose();
    _subtotalController.dispose();
    _taxAmountController.dispose();
    _totalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Verificar conectividad antes de cargar datos
  Future<bool> _checkConnectivity() async {
    try {
      //print('🌐 Verificando conectividad...');
      // Simular verificación de conectividad
      await Future.delayed(const Duration(milliseconds: 100));
      //print('✅ Conectividad verificada');
      return true;
    } catch (e) {
      //print('❌ Error verificando conectividad: $e');
      return false;
    }
  }

  // Método de fallback para cuando los servicios fallen
  void _loadFallbackData() {
    //print('🔄 Cargando datos de fallback...');
    
    setState(() {
      _isLoadingDropdowns = false;
      
      // Usar datos por defecto
      _transactionTypes = [
        TransactionType(
          code: 'PURCHASE',
          name: 'Compra',
          description: 'Compra de suministros a proveedores',
          color: '#4CAF50',
        ),
        TransactionType(
          code: 'DONATION',
          name: 'Donación',
          description: 'Suministros recibidos como donación',
          color: '#2196F3',
        ),
      ];
      
      _statusOptions = [
        StatusOption(
          code: 'PENDING',
          name: 'Pendiente',
          description: 'Transacción pendiente de procesar',
          color: '#FF9800',
        ),
        StatusOption(
          code: 'APPROVED',
          name: 'Aprobada',
          description: 'Transacción aprobada y procesada',
          color: '#4CAF50',
        ),
      ];
      
      //print('✅ Datos de fallback cargados');
      
      // Debug: verificar datos de fallback
      _debugData();
    });
  }

  Future<void> _loadInitialData() async {
    //print('🔄 Iniciando carga de datos iniciales...');
    try {
      //print('📋 Cargando datos de dropdowns...');
      await _loadDropdownData();
      //print('✅ Dropdowns cargados exitosamente');
      
      //print('📊 Cargando datos de transacción...');
      _loadTransactionData();
      //print('✅ Datos de transacción cargados exitosamente');
      
      //print('🎉 Carga inicial completada');
    } catch (e, stackTrace) {
      //print('❌ Error en _loadInitialData: $e');
      //print('📚 Stack trace: $stackTrace');
      
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error de Carga',
          desc: 'Error al cargar los datos iniciales: $e',
          btnOkText: 'Reintentar',
          btnOkOnPress: () {
            _loadInitialData();
          },
        ).show();
      }
    }
  }

  Future<void> _loadDropdownData() async {
    //print('🔄 Iniciando carga de dropdowns...');
    setState(() {
      _isLoadingDropdowns = true;
    });

    try {
      //print('🏢 Cargando proveedores...');
      final suppliers = await SupplierService.getAllSuppliers();
      //print('✅ Proveedores cargados: ${suppliers.length}');

      //print('📦 Cargando suministros...');
      final masterSupplies = await MasterSupplyService.getAllSupplies();
      //print('✅ Suministros cargados: ${masterSupplies.length}');

      //print('🏷️ Cargando tipos de transacción...');
      final transactionTypes = await SettingsService.getIncomingTransactionTypes();
      //print('✅ Tipos de transacción cargados: ${transactionTypes.length}');

      //print('📊 Cargando opciones de estado...');
      final statusOptions = await SettingsService.getIncomingStatusOptions();
      //print('✅ Opciones de estado cargadas: ${statusOptions.length}');

      setState(() {
        _suppliers = suppliers;
        _supplies = masterSupplies;
        _transactionTypes = transactionTypes;
        _statusOptions = statusOptions;
        _isLoadingDropdowns = false;
        
        //print('🔍 Validando datos de dropdowns...');
        _validateDropdownData();
        //print('✅ Validación completada');
        
        // Debug: verificar datos cargados
        _debugData();
      });

    } catch (e, stackTrace) {
      //print('❌ Error en _loadDropdownData: $e');
      print('📚 Stack trace: $stackTrace');
      
      //print('🔄 Intentando cargar datos de fallback...');
      _loadFallbackData();
      
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.warning,
          title: 'Advertencia',
          desc: 'Algunos servicios no están disponibles. Se han cargado datos por defecto.\n\nError: $e',
          btnOkText: 'Continuar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  void _loadTransactionData() {
    //print('🔄 Iniciando carga de datos de transacción...');
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      //print('📋 Argumentos recibidos: $args');
      
      if (args != null && args is int && args > 0) {
        //print('✏️ Modo edición - ID de transacción: $args');
        _transactionId = args;
        _isEditing = true;
        _loadTransaction();
      } else {
        //print('🆕 Modo nueva transacción');
        // Nueva transacción - generar número automático
        _transactionNumberController.text = IncomingTransactionService.generateTransactionNumber();
        _transactionDateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now().toLocal());
        _addDetail(); // Agregar primer detalle
        //print('✅ Nueva transacción inicializada');
      }
    } catch (e, stackTrace) {
      //print('❌ Error en _loadTransactionData: $e');
      //print('📚 Stack trace: $stackTrace');
      
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error de Carga',
          desc: 'Error al cargar datos de transacción: ($stackTrace) $e',
          btnOkText: 'Reintentar',
          btnOkOnPress: () {
            _loadTransactionData();
          },
        ).show();
      }
    }
  }

  Future<void> _loadTransaction() async {
    if (_transactionId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      //print('Cargando transacción ID: $_transactionId');
      
      // Verificar que los dropdowns estén cargados antes de cargar la transacción
      if (_suppliers.isEmpty || _supplies.isEmpty) {
        //print('Esperando a que se carguen los dropdowns...');
        await Future.delayed(const Duration(milliseconds: 500));
        if (_suppliers.isEmpty || _supplies.isEmpty) {
          throw Exception('Los datos de dropdowns no se han cargado correctamente');
        }
      }
      
      final transaction = await IncomingTransactionService.getIncomingTransactionById(_transactionId!);
      
      if (transaction != null) {
        //print('Transacción cargada: ${transaction.transactionNumber}');
        //print('Subtotal: ${transaction.subtotal} (tipo: ${transaction.subtotal.runtimeType})');
        //print('TaxAmount: ${transaction.taxAmount} (tipo: ${transaction.taxAmount.runtimeType})');
        //print('Total: ${transaction.total} (tipo: ${transaction.total.runtimeType})');
        
        setState(() {
          try {
            _transactionNumberController.text = transaction.transactionNumber;
            _transactionDateController.text = DateFormat('dd-MM-yyyy').format(DateTime.parse(transaction.transactionDate));
            _invoiceNumberController.text = transaction.invoiceNumber;
            
            // Convertir valores numéricos de forma segura
            final subtotal = _safeParseDouble(transaction.subtotal);
            final taxAmount = _safeParseDouble(transaction.taxAmount);
            final total = _safeParseDouble(transaction.total);
            
            //print('Valores convertidos - Subtotal: $subtotal, TaxAmount: $taxAmount, Total: $total');
            
            _subtotalController.text = subtotal.toStringAsFixed(2);
            _taxAmountController.text = taxAmount.toStringAsFixed(2);
            _totalController.text = total.toStringAsFixed(2);
            
            _notesController.text = transaction.notes;
            _selectedTransactionType = transaction.transactionType;
            _selectedStatus = transaction.status;
            
            // Buscar y asignar el proveedor seleccionado
            try {
              _selectedSupplier = _suppliers.firstWhere(
                (supplier) => supplier.supplierId == transaction.supplierId,
              );
            } catch (e) {
              //print('Error al buscar proveedor: $e');
              _selectedSupplier = null;
            }
            
            // Cargar detalles
            _details.clear();
            //print('Cargando ${transaction.details.length} detalles');
            for (var detail in transaction.details) {
              //print('Detalle - Quantity: ${detail.quantity} (tipo: ${detail.quantity.runtimeType})');
              //print('Detalle - UnitCost: ${detail.unitCost} (tipo: ${detail.unitCost.runtimeType})');
              //print('Detalle - Subtotal: ${detail.subtotal} (tipo: ${detail.subtotal.runtimeType})');
              
              final detailForm = IncomingDetailForm();
              
              // Verificar que el supplyId existe en la lista de suministros
              final supplyExists = _supplies.any((supply) => supply.supplyId == detail.supplyId);
              if (supplyExists) {
                detailForm.supplyId = detail.supplyId;
              } else {
                //print('Advertencia: supplyId ${detail.supplyId} no encontrado en la lista de suministros');
                detailForm.supplyId = 0; // Reset a 0 si no existe
              }
              
              // Convertir valores numéricos de forma segura
              final quantity = _safeParseDouble(detail.quantity);
              final unitCost = _safeParseDouble(detail.unitCost);
              final subtotal = _safeParseDouble(detail.subtotal);
              
              //print('Detalle convertido - Quantity: $quantity, UnitCost: $unitCost, Subtotal: $subtotal');
              
              detailForm.quantity = quantity;
              detailForm.unitCost = unitCost;
              detailForm.subtotal = subtotal;
              
              detailForm.quantityController.text = quantity.toStringAsFixed(2);
              detailForm.unitCostController.text = unitCost.toStringAsFixed(2);
              detailForm.subtotalController.text = subtotal.toStringAsFixed(2);
              detailForm.batchNumberController.text = detail.batchNumber;
              detailForm.expirationDateController.text = detail.expirationDate;
              detailForm.warehouseLocationController.text = detail.warehouseLocation;
              detailForm.notesController.text = detail.notes;
              _details.add(detailForm);
            }
            
            _isLoading = false;
          } catch (e) {
            //print('Error durante setState en _loadTransaction: $e');
            //print('Stack trace: ${StackTrace.current}');
            _isLoading = false;
            rethrow; // Re-lanzar el error para que sea capturado por el catch externo
          }
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          AwesomeDialog(
            context: context,
            animType: AnimType.bottomSlide,
            dialogType: DialogType.error,
            title: 'Error',
            desc: 'No se encontró la transacción',
            btnOkText: 'Cerrar',
            btnOkOnPress: () {
              Navigator.pop(context);
            },
          ).show();
        }
      }
    } catch (e) {
      //print('Error en _loadTransaction: $e');
      //print('Stack trace: ${StackTrace.current}');
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'Error al cargar la transacción: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {
            Navigator.pop(context);
          },
        ).show();
      }
    }
  }

  // Método de debug para verificar datos
  void _debugData() {
    print('🔍 === DEBUG DATA ===');
    print('📊 Proveedores: ${_suppliers.length}');
    print('📦 Suministros: ${_supplies.length}');
    print('🏷️ Tipos de transacción: ${_transactionTypes.length}');
    print('📊 Opciones de estado: ${_statusOptions.length}');
    print('📋 Detalles: ${_details.length}');
    print('✏️ Editando: $_isEditing');
    print('🔄 Cargando: $_isLoading');
    print('📋 Cargando dropdowns: $_isLoadingDropdowns');
    print('===================');
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        floatingActionButton: ButtonNavigationBar(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          children: [
            ButtonNavigationItem(
              label: " Guardar",
              height: 40,
              width: 130,
              icon: const Icon(Icons.save, color: Colors.white),
              color: Colors.green[200],
              onPressed: () async {
                await _guardarTransaccion();
              },
            ),
            ButtonNavigationItem(
              label: " Limpiar",
              height: 40,
              width: 130,
              icon: const Icon(Icons.clear, color: Colors.white),
              color: Colors.orange[200],
              onPressed: () async {
                _limpiarFormulario();
              },
            ),
            ButtonNavigationItem(
              label: " Recargar",
              height: 40,
              width: 130,
              icon: const Icon(Icons.refresh, color: Colors.white),
              color: Colors.blue[200],
              onPressed: () async {
                await _initializeData();
              },
            ),
          ],
        ),
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Editar Transacción de Ingreso' : 'Nueva Transacción de Ingreso',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: ButtonBack(),
          actions: [
            AppBarConnectionStatus(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: _isLoading || _isLoadingDropdowns
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isLoadingDropdowns 
                          ? 'Cargando configuración...'
                          : 'Cargando transacción...',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Por favor espere...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return Form(
                    key: _formKey,
                    child: SafeArea(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            children: [
                              // Sección de cabecera
                              _buildHeaderSection(),
                              // Sección de detalles grid
                              _buildDetailsSection2(),
                              // Sección de detalles
                              _buildDetailsSection(constraints.maxWidth),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      );
    } catch (e, stackTrace) {
      //print('❌ Error en build: $e');
      print('📚 Stack trace: $stackTrace');
      
      // UI de fallback en caso de error
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error de Renderizado...'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error al renderizar la pantalla',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(3),
      margin: const EdgeInsets.all(4),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Información de Cabecera',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                // Indicador de estado de datos
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _suppliers.isNotEmpty && _supplies.isNotEmpty 
                        ? Colors.green[100] 
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _suppliers.isNotEmpty && _supplies.isNotEmpty 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _suppliers.isNotEmpty && _supplies.isNotEmpty 
                            ? Icons.check_circle 
                            : Icons.warning,
                        size: 16,
                        color: _suppliers.isNotEmpty && _supplies.isNotEmpty 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _suppliers.isNotEmpty && _supplies.isNotEmpty 
                            ? 'Datos Cargados' 
                            : 'Cargando...',
                        style: TextStyle(
                          fontSize: 12,
                          color: _suppliers.isNotEmpty && _supplies.isNotEmpty 
                              ? Colors.green[700] 
                              : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                // Primera fila
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                      lg: 4,
                      xl: 4,
                      md: 4,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildTransactionNumberField(),
                      ),
                    ),
                    ResponsiveGridCol(
                      lg: 4,
                      xl: 4,
                      md: 4,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildTransactionDateField(),
                      ),
                    ),
                    ResponsiveGridCol(
                      lg: 4,
                      xl: 4,
                      md: 4,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildInvoiceNumberField(),
                      ),
                    ),
                  ],
                ),
                // Segunda fila
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                      lg: 4,
                      xl: 4,
                      md: 4,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildSupplierDropdown(),
                      ),
                    ),
                    ResponsiveGridCol(
                      lg: 4,
                      xl: 4,
                      md: 4,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildTransactionTypeDropdown(),
                      ),
                    ),
                    ResponsiveGridCol(
                      lg: 4,
                      xl: 4,
                      md: 4,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildStatusDropdown(),
                      ),
                    ),
                  ],
                ),
                // Tercera fila
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                      lg: 4,
                      xl: 4,
                      md: 4,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildSubtotalField(),
                      ),
                    ),
                    ResponsiveGridCol(
                      lg: 4,
                      xl: 4,
                      md: 4,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildTaxAmountField(),
                      ),
                    ),
                    ResponsiveGridCol(
                      lg: 4,
                      xl: 4,
                      md: 4,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildTotalField(),
                      ),
                    ),
                  ],
                ),
                // Cuarta fila
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                      lg: 12,
                      xl: 12,
                      md: 12,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildNotesField(),
                      ),
                    ),
              ],
            ),
              ]
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection2() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return  Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 5)
                    )
                  ]
              ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                      Text(
                        'Detalles de la Transacción',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addDetail,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Detalle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
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
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: PlutoGrid(
                                columns: columns,
                                rows: rowsLista(_lisDocumentDetails),
                                mode: PlutoGridMode.normal,    
                                onLoaded: (PlutoGridOnLoadedEvent event) {
                                  stateManager = event.stateManager;
                                  stateManager?.setKeepFocus(false);
                                  event.stateManager.setShowColumnFilter(true);
                                  event.stateManager.setShowColumnFooter(false);
                                },
                                onRowDoubleTap:(PlutoGridOnRowDoubleTapEvent event) async {
/*                                 if(event.cell.column.field=="id"){
                                    if (event.row.cells['fechaPrd']?.value!=DateTime.now()) {
                                     ToastSPA.showInfo(context, 'No es Posible Eliminar Registro', 2);
                                    } else {
                                      setState(() {_eliminadoReg = false;});
                                      await _eliminarReg(event.row.cells['id']?.value);
                                    }
                                }else if(event.cell.column.field=="id2"){
                                  if (event.row.cells['horaFin']?.value == '00:00:00') {
                                    Toast.showInfo(context, 'Cargando Datos de Tiempos de Cocción', 2);
                                    var tmpFechaPrd = _fechaPrdController.text;
                                    var tmpCiclo = _cicloController.text;
                                    _limpiarVar();
                                    setState(() {
                                      _estadoNuevo = false;
                                      _fechaPrdController.text = tmpFechaPrd;
                                      _cicloController.text = tmpCiclo;
                                      _idDocumentoController.text = event.row.cells['id2']!.value.toString();
                                      _fechaPrdController.text = event.row.cells['fechaPrd']?.value;
                                      _cicloController.text = event.row.cells['ciclo']?.value;
                                      _hornoController.text = event.row.cells['horno']?.value;
                                      _valueHorno = event.row.cells['horno']?.value;
                                      _horaInicioController.text = event.row.cells['horaInicio']?.value;
                                      _horaFinController.text = event.row.cells['horaFin']?.value;
                                      _horaCalculoController.text = event.row.cells['horaCalculo']?.value;
                                      _temperaturaCorteCoccionController.text = event.row.cells['temperaturaCorteCoccion']?.value;
                                      _temperaturaSondaController.text = event.row.cells['temperaturaSondaIni1']?.value;
                                      _temperaturaSondaController2.text = event.row.cells['temperaturaSondaIni2']?.value;
                                      _temperaturaSondaController3.text = event.row.cells['temperaturaSondaIni3']?.value;
                                      _temperaturaSondaController4.text = event.row.cells['temperaturaSondaIni4']?.value;
                                      _temperaturaSondaController5.text = event.row.cells['temperaturaSondaFin1']?.value;
                                      _temperaturaSondaController6.text = event.row.cells['temperaturaSondaFin2']?.value;
                                      _temperaturaSondaController7.text = event.row.cells['temperaturaSondaFin3']?.value;
                                      _temperaturaSondaController8.text = event.row.cells['temperaturaSondaFin4']?.value;
                                      _temperaturaAmbienteController.text = event.row.cells['temperaturaAmbiente']?.value;
                                      _temperaturaAmbienteController2.text = event.row.cells['temperaturaAmbiente2']?.value;
                                      _temperaturaAmbienteController3.text = event.row.cells['temperaturaAmbiente3']?.value;
                                    });
                                    showModalBottomSheet(context: context,
                                      isDismissible: false,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      builder: (BuildContext context) {
                                        return _buildStatefulBuilderAddDet(true);
                                      }
                                    );
                                  } else {
                                    ToastSPA.showInfo(context, 'No es Posible Editar. Tiempos de Cocción Finalizado...', 2);
                                  }
                                }
 */                              },
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
          );

  }

  

  Widget _buildDetailsSection(double maxWidth) {
    return Container(
      padding: const EdgeInsets.all(3),
      margin: const EdgeInsets.all(5),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalles de la Transacción',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addDetail,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Detalle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (_details.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No hay detalles agregados. Haga clic en "Agregar Detalle" para comenzar.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _details.length,
              itemBuilder: (context, index) {
                return _buildDetailCard(index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(int index) {
    final detail = _details[index];
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalle ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeDetail(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Eliminar detalle',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Primera fila
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    child: _buildSupplyDropdown(detail),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    child: _buildQuantityField(detail),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Segunda fila
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    child: _buildUnitCostField(detail),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    child: _buildSubtotalDetailField(detail),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Tercera fila
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    child: _buildBatchNumberField(detail),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    child: _buildExpirationDateField(detail),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Cuarta fila
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    child: _buildWarehouseLocationField(detail),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    child: _buildDetailNotesField(detail),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CAMPOS DE CABECERA ====================

  TextFormField _buildTransactionNumberField() {
    return TextFormField(
      controller: _transactionNumberController,
      readOnly: _isEditing,
      decoration: const InputDecoration(
        labelText: 'Número de Transacción *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el número de transacción';
        }
        return null;
      },
    );
  }

  TextFormField _buildTransactionDateField() {
    return TextFormField(
      controller: _transactionDateController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Fecha de Transacción *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese la fecha de transacción';
        }
        return null;
      },
      onTap: () async {
        DateTime? pickedDate =
            await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime( 2050));
                                              
        if (pickedDate != null) {
          String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
          setState(() {
            _transactionDateController.text = formattedDate;
          });
        } else {
          _transactionDateController.clear();
        }
      },      
    );
  }

  DropdownButtonFormField<Supplier> _buildSupplierDropdown() {
    // Verificar que hay proveedores disponibles
    if (_suppliers.isEmpty) {
      return DropdownButtonFormField<Supplier>(
        value: null,
        decoration: const InputDecoration(
          labelText: 'Proveedor *',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          hintText: 'No hay proveedores disponibles',
        ),
        items: const [],
        onChanged: null,
        validator: (value) {
          return 'No hay proveedores disponibles';
        },
      );
    }

    return DropdownButtonFormField<Supplier>(
      value: _selectedSupplier != null && _suppliers.any((s) => s.supplierId == _selectedSupplier!.supplierId) 
          ? _selectedSupplier 
          : null,
      decoration: const InputDecoration(
        labelText: 'Proveedor *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      validator: (value) {
        if (value == null) {
          return 'Seleccione un proveedor';
        }
        return null;
      },
      items: _suppliers.map((supplier) {
        return DropdownMenuItem<Supplier>(
          value: supplier,
          child: Text('${supplier.name} (${supplier.code})'),
        );
      }).toList(),
      onChanged: (Supplier? newValue) {
        setState(() {
          _selectedSupplier = newValue;
          // Limpiar detalles cuando cambia el proveedor
          if (newValue != null) {
            _clearDetails();
          }
        });
      },
    );
  }

  TextFormField _buildInvoiceNumberField() {
    return TextFormField(
      controller: _invoiceNumberController,
      decoration: const InputDecoration(
        labelText: 'Número de Factura *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el número de factura';
        }
        return null;
      },
    );
  }

  DropdownButtonFormField<String> _buildTransactionTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTransactionType,
      decoration: const InputDecoration(
        labelText: 'Tipo de Transacción *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      items: _transactionTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type.code,
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
/*                   Text(
                    type.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ), */
                ],
              ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedTransactionType = newValue!;
        });
      },
    );
  }

  DropdownButtonFormField<String> _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Estado *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      items: _statusOptions.map((status) {
        return DropdownMenuItem<String>(
          value: status.code,
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
/*                     Text(
                      status.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ), */
                  ],
                ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedStatus = newValue!;
        });
      },
    );
  }

  TextFormField _buildSubtotalField() {
    return TextFormField(
      controller: _subtotalController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Subtotal',
        prefixText: '\$ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildTaxAmountField() {
    return TextFormField(
      controller: _taxAmountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Impuestos *',
        prefixText: '\$ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese los impuestos';
        }
        if (double.tryParse(value) == null) {
          return 'Ingrese un número válido';
        }
        final taxAmount = double.tryParse(value) ?? 0.0;
        if (taxAmount < 0) {
          return 'Los impuestos no pueden ser negativos';
        }
        return null;
      },
      onChanged: (value) {
        _calculateTotal();
      },
    );
  }

  TextFormField _buildTotalField() {
    return TextFormField(
      controller: _totalController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Total',
        prefixText: '\$ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      //maxLines: 2,
      showCursor: true,
      maxLength: 400,
      textCapitalization: TextCapitalization.sentences,
      inputFormatters: [UpperCaseTextFormatter()],
      keyboardType: TextInputType.text,
      style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w500),
      decoration: const InputDecoration(
        labelText: 'Notas',
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  // ==================== CAMPOS DEl GRID DE DETALLE ====================

  List<PlutoRow> rowsLista(List info) {
    List<PlutoRow> retorno = [];
    try {
      for (var rowInfo in info) {
        retorno.add(PlutoRow(
          cells: {
            'detail_id': PlutoCell(value: rowInfo['detail_id']),
            'incoming_id': PlutoCell(value: rowInfo['incoming_id']),
            'supply_id': PlutoCell(value: rowInfo['supply_id']),
            'quantity': PlutoCell(value: rowInfo['quantity']),
            'unit_cost': PlutoCell(value: rowInfo['unit_cost']),
            'subtotal': PlutoCell(value: rowInfo['subtotal']),
            'batch_number': PlutoCell(value: rowInfo['batch_number']),
            'expiration_date': PlutoCell(value: rowInfo['expiration_date']),
            'warehouse_location': PlutoCell(value: rowInfo['warehouse_location']),
            'notes': PlutoCell(value: rowInfo['notes']),
            'id2': PlutoCell(value: rowInfo['detail_id']),
            'id3': PlutoCell(value: rowInfo['detail_id']),
          },
        ));
      }
      
    } on Exception catch(e) {
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
    Color? colorHeader = Colors.lightBlueAccent;
    List<PlutoColumn> list = [];

    list.add(PlutoColumn(
      title: 'detail_id',
      field: 'detail_id',
      backgroundColor: colorHeader,
      readOnly: true,
      width: 145,
      minWidth: 145,
      type: PlutoColumnType.text(),
      hide: true,
    ));
    list.add(PlutoColumn(
      title: 'incoming_id',
      field: 'incoming_id',
      backgroundColor: colorHeader,
      readOnly: true,
      width: 120,
      type: PlutoColumnType.text(),
      hide: true,
      enableHideColumnMenuItem: false,
      enableContextMenu: false,
      enableSetColumnsMenuItem: false,  
    ));
    list.add(PlutoColumn(
      title: 'Producto',
      field: 'supply_id',
      backgroundColor: colorHeader,
      readOnly: true, // Solo lectura, no permite selección
      width: 200, // Más ancho para mostrar nombre + código
      textAlign: PlutoColumnTextAlign.start,
      type: PlutoColumnType.text(),
      enableHideColumnMenuItem: false,
      enableFilterMenuItem: false,
      enableContextMenu: false,
      enableSetColumnsMenuItem: false,
      // Formateador para mostrar name + code en lugar del ID
      formatter: (value) {
        if (value == null || value == 0) return 'Sin asignar';
        
        try {
          final supply = _supplies.firstWhere(
            (s) => s.supplyId == value,
            orElse: () => MasterSupply(
              supplyId: 0, 
              code: 'N/A',
              name: 'Producto no encontrado', 
              description: 'Producto no disponible',
              category: 'N/A',
              unitMeasure: 'N/A',
              presentation: 'N/A',
              unitCost: 0.0,
              salePrice: 0.0,
              minStock: 0,
              maxStock: 0,
              mainSupplier: 'N/A',
              warehouseLocation: 'N/A',
              status: false,
            ),
          );
          
          if (supply.supplyId == 0) return 'Producto no encontrado';
          return '${supply.name} (${supply.code})';
        } catch (e) {
          return 'Error al cargar producto';
        }
      },
    ));
    list.add(PlutoColumn(
      title: 'Cantidad',
      field: 'quantity',
      backgroundColor: colorHeader,
      readOnly: true,
      width: 130,
      textAlign: PlutoColumnTextAlign.center,
      type: PlutoColumnType.text(),
      enableHideColumnMenuItem: false,
      enableFilterMenuItem: false,
      enableContextMenu: false,
      enableSetColumnsMenuItem: false,       
    ));
    list.add(PlutoColumn(
      title: 'Costo Unitario',
      field: 'unit_cost',
      backgroundColor: colorHeader,
      readOnly: true,
      width: 130,
      textAlign: PlutoColumnTextAlign.center,
      type: PlutoColumnType.text(),
      enableHideColumnMenuItem: false,
      enableFilterMenuItem: false,
      enableContextMenu: false,
      enableSetColumnsMenuItem: false,       
    ));
    list.add(PlutoColumn(
      title: 'Sub Total',
      field: 'subtotal',
      backgroundColor: colorHeader,
      width: 120,
      readOnly: true,
      textAlign: PlutoColumnTextAlign.center,
      type: PlutoColumnType.text(),
      enableHideColumnMenuItem: false,
      enableFilterMenuItem: false,
      enableContextMenu: false,
      enableSetColumnsMenuItem: false,       
    ));
    list.add(PlutoColumn(
      title: 'Número de Lote',
      field: 'batch_number',
      backgroundColor: colorHeader,
      readOnly: true,
      width: 120,
      textAlign: PlutoColumnTextAlign.center,
      type: PlutoColumnType.text(),
      enableHideColumnMenuItem: false,
      enableFilterMenuItem: false,
      enableContextMenu: false,
      enableSetColumnsMenuItem: false,       
    ));
    list.add(PlutoColumn(
      title: 'Fecha de Vencimiento',
      field: 'expiration_date',
      backgroundColor: colorHeader,
      readOnly: true,
      width: 120,
      textAlign: PlutoColumnTextAlign.center,
      type: PlutoColumnType.text(),
      enableHideColumnMenuItem: false,
      enableFilterMenuItem: false,
      enableContextMenu: false,
      enableSetColumnsMenuItem: false,       
    ));
    list.add(PlutoColumn(
      title: 'Ubicación',
      field: 'warehouse_location',
      backgroundColor: colorHeader,
      readOnly: true,
      width: 120,
      textAlign: PlutoColumnTextAlign.center,
      type: PlutoColumnType.text(),
      enableHideColumnMenuItem: false,
      enableFilterMenuItem: false,
      enableContextMenu: false,
      enableSetColumnsMenuItem: false,       
    ));
    list.add(PlutoColumn(
      title: 'Notas',
      field: 'notes',
      backgroundColor: colorHeader,
      readOnly: true,
      width: 120,
      textAlign: PlutoColumnTextAlign.center,
      type: PlutoColumnType.text(),
      enableHideColumnMenuItem: false,
      enableFilterMenuItem: false,
      enableContextMenu: false,
      enableSetColumnsMenuItem: false,       
    ));

    list.add(PlutoColumn(
      title: 'Editar',
      field: 'id2',
      backgroundColor: colorHeader,
      type: PlutoColumnType.number(),
      width: 65,
      minWidth: 60,
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
              child: IconButton(
                icon: const Image(image: AssetImage('assets/images/iconsEdit24.png'),),
                onPressed: () {
                },
                iconSize: 15,
                padding: const EdgeInsets.all(0),
              ),
            ),
          ],
        );
    }));
    list.add(PlutoColumn(
    title: 'Eliminar',
    field: 'id3',
    backgroundColor: colorHeader,
    type: PlutoColumnType.number(),
    width: 65,
    minWidth: 60,
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
            child: IconButton(
              icon: const Image(image: AssetImage('assets/images/eliminar_32x32.png'),),
              onPressed: () {
              },
              iconSize: 15,
              padding: const EdgeInsets.all(0),
            ),
          ),
        ],
      );
  }));
  return list;
  }

// ==================== CAMPOS DE DETALLE ====================

  DropdownButtonFormField<MasterSupply> _buildSupplyDropdown(IncomingDetailForm detail) {
    // Verificar que hay suministros disponibles
    if (_supplies.isEmpty) {
      return DropdownButtonFormField<MasterSupply>(
        value: null,
        decoration: const InputDecoration(
          labelText: 'Producto *',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          hintText: 'No hay productos disponibles',
        ),
        items: const [],
        onChanged: null,
      );
    }

    // Buscar el suministro seleccionado en la lista
    MasterSupply? selectedSupply;
    try {
      // Solo buscar si el supplyId es válido (mayor a 0)
      if (detail.supplyId > 0) {
        selectedSupply = _supplies.firstWhere(
          (supply) => supply.supplyId == detail.supplyId,
        );
      } else {
        selectedSupply = null;
      }
    } catch (e) {
      // Si no se encuentra, no seleccionar nada
      //print('Suministro con ID ${detail.supplyId} no encontrado: $e');
      selectedSupply = null;
    }

    return DropdownButtonFormField<MasterSupply>(
      value: selectedSupply,
      decoration: const InputDecoration(
        labelText: 'Producto *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      items: _supplies.map((supply) {
        return DropdownMenuItem<MasterSupply>(
          value: supply,
          child: Text('${supply.name} (${supply.code})'),
        );
      }).toList(),
      onChanged: (MasterSupply? newValue) {
        if (newValue != null) {
          setState(() {
            detail.supplyId = newValue.supplyId ?? 0;
            detail.unitCost = newValue.unitCost;
            detail.calculateSubtotal();
          });
          _calculateTotals();
        }
      },
    );
  }

  TextFormField _buildQuantityField(IncomingDetailForm detail) {
    return TextFormField(
      controller: detail.quantityController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Cantidad *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese la cantidad';
        }
        if (double.tryParse(value) == null) {
          return 'Ingrese un número válido';
        }
        final quantity = double.tryParse(value) ?? 0.0;
        if (quantity <= 0) {
          return 'La cantidad debe ser mayor a 0';
        }
        return null;
      },
      onChanged: (value) {
        detail.calculateSubtotal();
        _calculateTotals();
      },
    );
  }

  TextFormField _buildUnitCostField(IncomingDetailForm detail) {
    return TextFormField(
      controller: detail.unitCostController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Costo Unitario *',
        prefixText: '\$ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el costo unitario';
        }
        if (double.tryParse(value) == null) {
          return 'Ingrese un número válido';
        }
        final unitCost = double.tryParse(value) ?? 0.0;
        if (unitCost < 0) {
          return 'El costo no puede ser negativo';
        }
        return null;
      },
      onChanged: (value) {
        detail.calculateSubtotal();
        _calculateTotals();
      },
    );
  }

  TextFormField _buildSubtotalDetailField(IncomingDetailForm detail) {
    return TextFormField(
      controller: detail.subtotalController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Subtotal',
        prefixText: '\$ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildBatchNumberField(IncomingDetailForm detail) {
    return TextFormField(
      controller: detail.batchNumberController,
      maxLength: 50,
      decoration: const InputDecoration(
        labelText: 'Número de Lote',
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildExpirationDateField(IncomingDetailForm detail) {
    return TextFormField(
      controller: detail.expirationDateController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Fecha de Vencimiento',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese la fecha de Vencimiento';
        }
        return null;
      },      
      onTap: () async {
        DateTime? pickedDate =
            await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime( 2050));
                                              
        if (pickedDate != null) {
          String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
          setState(() {
            detail.expirationDateController.text = formattedDate;
          });
        } else {
          detail.expirationDateController.clear();
        }
      },       
    );
  }

  TextFormField _buildWarehouseLocationField(IncomingDetailForm detail) {
    return TextFormField(
      controller: detail.warehouseLocationController,
      maxLength: 100,
      decoration: const InputDecoration(
        labelText: 'Ubicación en Almacén',
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildDetailNotesField(IncomingDetailForm detail) {
    return TextFormField(
      controller: detail.notesController,
      decoration: const InputDecoration(
        labelText: 'Notas del Detalle',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  // ==================== MÉTODOS DE GESTIÓN ====================

  void _addDetail() {
    setState(() {
      _details.add(IncomingDetailForm());
    });
  }

  void _removeDetail(int index) {
    setState(() {
      _details.removeAt(index);
    });
    _calculateTotals();
  }

  void _clearDetails() {
    setState(() {
      _details.clear();
      _addDetail(); // Add one detail to ensure there's at least one
    });
  }

  void _validateDropdownData() {
    // Validar que el proveedor seleccionado existe en la lista
    if (_selectedSupplier != null && !_suppliers.any((s) => s.supplierId == _selectedSupplier!.supplierId)) {
      //print('Proveedor seleccionado no encontrado en la lista, reseteando...');
      _selectedSupplier = null;
    }
    
    // Validar que todos los detalles tienen supplyIds válidos
    for (var detail in _details) {
      if (detail.supplyId > 0 && !_supplies.any((s) => s.supplyId == detail.supplyId)) {
        //print('Detalle con supplyId ${detail.supplyId} no encontrado, reseteando...');
        detail.supplyId = 0;
      }
    }
  }

  void _calculateTotals() {
    double subtotal = 0;
    for (var detail in _details) {
      subtotal += detail.subtotal;
    }
    
    _subtotalController.text = subtotal.toStringAsFixed(2);
    _calculateTotal();
  }

  void _calculateTotal() {
    double subtotal = double.tryParse(_subtotalController.text) ?? 0;
    double taxAmount = double.tryParse(_taxAmountController.text) ?? 0;
    double total = subtotal + taxAmount;
    
    _totalController.text = total.toStringAsFixed(2);
  }

  void _limpiarFormulario() {
    _transactionNumberController.clear();
    _transactionDateController.clear();
    _invoiceNumberController.clear();
    _subtotalController.clear();
    _taxAmountController.clear();
    _totalController.clear();
    _notesController.clear();
    
    setState(() {
      _selectedSupplier = null;
      _selectedTransactionType = _transactionTypes.isNotEmpty ? _transactionTypes.first.code : 'PURCHASE';
      _selectedStatus = _statusOptions.isNotEmpty ? _statusOptions.first.code : 'PENDING';
      _details.clear();
    });
    
    // Regenerar número de transacción y fecha
    _transactionNumberController.text = IncomingTransactionService.generateTransactionNumber();
    _transactionDateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now().toLocal());
    _addDetail();
  }

  Future<void> _guardarTransaccion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSupplier == null) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Proveedor Requerido',
        desc: 'Por favor seleccione un proveedor',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    if (_details.isEmpty) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Detalles Requeridos',
        desc: 'Debe agregar al menos un detalle a la transacción',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    // Validar detalles
    for (int i = 0; i < _details.length; i++) {
      final detail = _details[i];
      if (detail.supplyId == 0) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.warning,
          title: 'Suministro Requerido',
          desc: 'Por favor seleccione un suministro en el detalle ${i + 1}',
          btnOkText: 'Entendido',
          btnOkOnPress: () {},
        ).show();
        return;
      }
    }

    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: _isEditing ? 'Actualizando transacción...' : 'Guardando transacción...');

    try {
      // Crear lista de detalles
      final details = _details.map((detail) => CreateIncomingDetail(
        supplyId: detail.supplyId,
        quantity: detail.quantity,
        unitCost: detail.unitCost,
        subtotal: detail.subtotal,
        batchNumber: detail.batchNumber,
        expirationDate: detail.expirationDate,
        warehouseLocation: detail.warehouseLocation,
        notes: detail.notes,
      )).toList();

      if (_isEditing) {
        // Actualizar transacción existente
        final transaction = IncomingTransaction(
          incomingId: _transactionId!,
          transactionNumber: _transactionNumberController.text.trim(),
          transactionDate: _transactionDateController.text.trim(),
          supplierId: _selectedSupplier!.supplierId!,
          invoiceNumber: _invoiceNumberController.text.trim(),
          transactionType: _selectedTransactionType,
          subtotal: double.tryParse(_subtotalController.text.trim()) ?? 0.0,
          taxAmount: double.tryParse(_taxAmountController.text.trim()) ?? 0.0,
          total: double.tryParse(_totalController.text.trim()) ?? 0.0,
          notes: _notesController.text.trim(),
          status: _selectedStatus,
          details: details.map((d) => IncomingDetail(
            detailId: 0,
            incomingId: _transactionId!,
            supplyId: d.supplyId,
            quantity: d.quantity,
            unitCost: d.unitCost,
            subtotal: d.subtotal,
            batchNumber: d.batchNumber,
            expirationDate: d.expirationDate,
            warehouseLocation: d.warehouseLocation,
            notes: d.notes,
          )).toList(),
        );

        await IncomingTransactionService.updateIncomingTransaction(transaction);
      } else {
        // Crear nueva transacción
        final transaction = CreateIncomingTransaction(
          transactionNumber: _transactionNumberController.text.trim(),
          transactionDate: _transactionDateController.text.trim(),
          supplierId: _selectedSupplier!.supplierId!,
          invoiceNumber: _invoiceNumberController.text.trim(),
          transactionType: _selectedTransactionType,
          subtotal: double.tryParse(_subtotalController.text.trim()) ?? 0.0,
          taxAmount: double.tryParse(_taxAmountController.text.trim()) ?? 0.0,
          total: double.tryParse(_totalController.text.trim()) ?? 0.0,
          notes: _notesController.text.trim(),
          details: details,
        );

        await IncomingTransactionService.createIncomingTransaction(transaction);
      }

      pr.close();

      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.success,
          title: 'Éxito',
          desc: _isEditing 
              ? 'Transacción actualizada correctamente'
              : 'Transacción creada correctamente',
          btnOkText: 'Aceptar',
          btnOkOnPress: () {
            Navigator.pop(context);
          },
        ).show();
      }
    } catch (e) {
      pr.close();
      
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'Error al guardar la transacción: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  // Método auxiliar para convertir valores a double de forma segura
  double _safeParseDouble(dynamic value) {
    //print('_safeParseDouble recibió: $value (tipo: ${value.runtimeType})');
    
    if (value == null) {
      //print('Valor es null, retornando 0.0');
      return 0.0;
    }
    
    if (value is double) {
      //print('Valor ya es double: $value');
      return value;
    }
    
    if (value is int) {
      //print('Valor es int, convirtiendo a double: ${value.toDouble()}');
      return value.toDouble();
    }
    
    if (value is String) {
      //print('Valor es string: "$value"');
      final parsed = double.tryParse(value);
      if (parsed != null) {
        //print('String parseado exitosamente: $parsed');
        return parsed;
      } else {
        //print('No se pudo parsear string, retornando 0.0');
        return 0.0;
      }
    }
    
    // Si es otro tipo, intentar convertir a string y luego a double
    //print('Tipo desconocido, intentando convertir a string');
    try {
      final stringValue = value.toString();
      //print('Convertido a string: "$stringValue"');
      final parsed = double.tryParse(stringValue);
      if (parsed != null) {
        //print('String parseado exitosamente: $parsed');
        return parsed;
      } else {
        //print('No se pudo parsear string convertido, retornando 0.0');
        return 0.0;
      }
    } catch (e) {
      //print('Error al convertir a string: $e, retornando 0.0');
      return 0.0;
    }
  }
}

// Clase auxiliar para manejar los formularios de detalles
class IncomingDetailForm {
  int supplyId = 0;
  double quantity = 0;
  double unitCost = 0;
  double subtotal = 0;

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitCostController = TextEditingController();
  final TextEditingController subtotalController = TextEditingController();
  final TextEditingController batchNumberController = TextEditingController();
  final TextEditingController expirationDateController = TextEditingController();
  final TextEditingController warehouseLocationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  void calculateSubtotal() {
    quantity = double.tryParse(quantityController.text) ?? 0;
    unitCost = double.tryParse(unitCostController.text) ?? 0;
    subtotal = quantity * unitCost;
    subtotalController.text = subtotal.toStringAsFixed(2);
  }

  String get batchNumber => batchNumberController.text.trim();
  String get expirationDate => expirationDateController.text.trim();
  String get warehouseLocation => warehouseLocationController.text.trim();
  String get notes => notesController.text.trim();
} 