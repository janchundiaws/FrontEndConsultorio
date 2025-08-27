/* Autor: Pio enrique Olvera Briones
   Fecha: 26/08/2025
   Descripción: pantalla para crear/editar transacciones de egreso de insumos
*/

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:button_navigation_bar/button_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:odontologo/services/outgoing_transaction_service.dart';
import 'package:odontologo/services/master_supply_service.dart';
import 'package:odontologo/services/settings_service.dart';
import 'package:odontologo/services/dentist_service.dart';
import 'package:odontologo/object/outgoing_transaction.dart';
import 'package:odontologo/object/master_supply.dart';
import 'package:odontologo/object/transaction_type.dart';
import 'package:odontologo/widgets/connection_status.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:odontologo/services/mayusculas.dart';
import 'package:intl/intl.dart';

class TransaccionEgreso extends StatefulWidget {
  const TransaccionEgreso({super.key});

  @override
  State<TransaccionEgreso> createState() => _TransaccionEgresoState();
}

class _TransaccionEgresoState extends State<TransaccionEgreso> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cabecera
  final _transactionNumberController = TextEditingController();
  final _transactionDateController = TextEditingController();
  final _reasonController = TextEditingController();
  final _totalController = TextEditingController();

  // Dropdowns y selecciones
  List<MasterSupply> _supplies = [];
  List<TransactionType> _transactionTypes = [];
  List<StatusOption> _statusOptions = [];
  List<Map<String, String>> _dentists = [];
  String _selectedTransactionType = 'CONSUMPTION';
  String _selectedStatus = 'PENDING';
  String _selectedDentist = '0';

  // Paciente/Dentista IDs (inputs simples por ahora)
  final _patientIdController = TextEditingController();
  final _dentistIdController = TextEditingController();

  // Detalles con PlutoGrid
  final List<OutgoingDetailForm> _details = [];
  PlutoGridStateManager? stateManager;
  List<PlutoColumn> columns = [];
  final List _lisDocumentDetails = [];

  int? _transactionId;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isLoadingDropdowns = false;

  @override
  void initState() {
    super.initState();
    columns = _columnsRender();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _transactionNumberController.dispose();
    _transactionDateController.dispose();
    _reasonController.dispose();
    _totalController.dispose();
    _patientIdController.dispose();
    _dentistIdController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadDropdownData();
    _loadTransactionData();
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      _isLoadingDropdowns = true;
    });
    try {
      // Cargar suministros
      final supplies = await MasterSupplyService.getAllSupplies();

      // Cargar tipos de transacción de egreso
      final transactionTypes = await SettingsService.getOutgoingTransactionTypes();

      // Cargar opciones de estado de egreso
      final statusOptions = await SettingsService.getOutgoingStatusOptions();

      // Cargar doctores desde la API
      final dentists = await DentistService.getDentistsForDropdown();

      setState(() {
        _supplies = supplies;
        _transactionTypes = transactionTypes;
        _statusOptions = statusOptions;
        _dentists = dentists;
        _isLoadingDropdowns = false;

        // Aplicar validación para asegurar valores únicos
        _validateDropdownData();
      });
    } catch (e) {
      setState(() {
        _isLoadingDropdowns = false;
      });

      // Cargar datos de fallback
      await _loadFallbackData();

      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.warning,
          title: 'Advertencia',
          desc:
              'Algunos servicios no están disponibles. Se han cargado datos por defecto.\n\nError: $e',
          btnOkText: 'Continuar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  // Método de fallback para cuando los servicios fallen
  Future<void> _loadFallbackData() async {
    setState(() async {
      _isLoadingDropdowns = false;

      // Solo usar datos por defecto si no hay datos existentes
      if (_transactionTypes.isEmpty) {
        _transactionTypes = [
          TransactionType(
            code: 'CONSUMPTION',
            name: 'Consumo',
            description: 'Consumo interno de suministros',
            color: '#FF5722',
          ),
          TransactionType(
            code: 'SALE',
            name: 'Venta',
            description: 'Venta de suministros a clientes',
            color: '#4CAF50',
          ),
          TransactionType(
            code: 'LOSS',
            name: 'Pérdida',
            description: 'Pérdida o daño de suministros',
            color: '#F44336',
          ),
          TransactionType(
            code: 'ADJUSTMENT',
            name: 'Ajuste',
            description: 'Ajuste de inventario',
            color: '#2196F3',
          ),
        ];
      }

      // Solo usar opciones de estado por defecto si no hay datos existentes
      if (_statusOptions.isEmpty) {
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
          StatusOption(
            code: 'REJECTED',
            name: 'Rechazada',
            description: 'Transacción rechazada',
            color: '#F44336',
          ),
        ];
      }

      // Solo usar doctores por defecto si no hay datos existentes
      if (_dentists.isEmpty) {
        try {
          // Intentar cargar dentistas desde la API como respaldo
          final dentists = await DentistService.getDentistsForDropdown();
          _dentists = dentists;
        } catch (e) {
          // Si falla, usar datos por defecto
          _dentists = [
            {'codigo': '0', 'descripcion': 'Sin selección'},
          ];
        }
      }
      
      // Aplicar validación para asegurar valores únicos
      _validateDropdownData();
    });
  }

  void _validateDropdownData() {
    // Eliminar duplicados basándose en el código único
    _transactionTypes = _transactionTypes.toSet().toList();
    _statusOptions = _statusOptions.toSet().toList();
    
    // Si no hay tipos de transacción, usar solo los por defecto
    if (_transactionTypes.isEmpty) {
      _transactionTypes = [
        TransactionType(
          code: 'CONSUMPTION',
          name: 'Consumo',
          description: 'Consumo interno de suministros',
          color: '#FF5722',
        ),
      ];
    }
    
    // Si no hay opciones de estado, usar solo las por defecto
    if (_statusOptions.isEmpty) {
      _statusOptions = [
        StatusOption(
          code: 'PENDING',
          name: 'Pendiente',
          description: 'Transacción pendiente de procesar',
          color: '#FF9800',
        ),
      ];
    }
    
    // Si no hay doctores, usar solo los por defecto
    if (_dentists.isEmpty) {
      _dentists = [
        {'codigo': '0', 'descripcion': 'Sin selección'},
      ];
    }
    
    // Verificar que no haya valores duplicados en el dropdown
    _ensureUniqueValues();
  }
  
  void _ensureUniqueValues() {
    // Asegurar que no haya valores duplicados para el dropdown
    final uniqueTransactionTypes = <String, TransactionType>{};
    for (final type in _transactionTypes) {
      uniqueTransactionTypes[type.name] = type;
    }
    _transactionTypes = uniqueTransactionTypes.values.toList();
    
    final uniqueStatusOptions = <String, StatusOption>{};
    for (final status in _statusOptions) {
      uniqueStatusOptions[status.name] = status;
    }
    _statusOptions = uniqueStatusOptions.values.toList();

    final uniqueDentists = <String, Map<String, String>>{};
    for (final dentist in _dentists) {
      uniqueDentists[dentist['codigo'] ?? ''] = dentist;
    }
    _dentists = uniqueDentists.values.toList();
  }

  // Método para recargar los dentistas desde la API
  Future<void> _reloadDentists() async {
    try {
      setState(() {
        _isLoadingDropdowns = true;
      });

      // Limpiar caché de dentistas
      SettingsService.clearCache();
      
      // Cargar dentistas desde la API
      final dentists = await DentistService.getDentistsForDropdown();
      
      setState(() {
        _dentists = dentists;
        _isLoadingDropdowns = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDropdowns = false;
      });
      
      if (mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'No se pudieron recargar los dentistas: $e',
          btnOkText: 'Entendido',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  // Método para sincronizar detalles con el grid
  void _syncDetailsWithGrid() {
    setState(() {
      _lisDocumentDetails.clear();

      for (int i = 0; i < _details.length; i++) {
        final detail = _details[i];
        _lisDocumentDetails.add({
          'detail_id': detail.detailId ?? 0,
          'outgoing_id': _transactionId ?? 0,
          'supply_id': detail.supplyId,
          'quantity': detail.quantity,
          'unit_cost': detail.unitCost,
          'subtotal': detail.subtotal,
          'batch_number': detail.batchNumber,
          'notes': detail.notes,
        });
      }

      // Actualizar grid si está cargado
      if (stateManager != null) {
        stateManager!.notifyListeners();
        stateManager!.removeRows(stateManager!.rows);
        stateManager!.appendRows(rowsLista(_lisDocumentDetails));
      }
    });
  }

  // Método para convertir detalles a filas del grid
  List<PlutoRow> rowsLista(List info) {
    List<PlutoRow> retorno = [];
    try {
      for (var rowInfo in info) {
        retorno.add(
          PlutoRow(
            cells: {
              'detail_id': PlutoCell(value: rowInfo['detail_id']),
              'outgoing_id': PlutoCell(value: rowInfo['outgoing_id']),
              'supply_id': PlutoCell(value: rowInfo['supply_id']),
              'quantity': PlutoCell(value: rowInfo['quantity']),
              'unit_cost': PlutoCell(value: rowInfo['unit_cost']),
              'subtotal': PlutoCell(value: rowInfo['subtotal']),
              'batch_number': PlutoCell(value: rowInfo['batch_number']),
              'notes': PlutoCell(value: rowInfo['notes']),
              'id2': PlutoCell(value: rowInfo['detail_id']),
              'id3': PlutoCell(value: rowInfo['detail_id']),
            },
          ),
        );
      }
    } on Exception catch (e) {
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
    return retorno;
  }

  // Método para definir las columnas del grid
  List<PlutoColumn> _columnsRender() {
    Color? colorHeader = Colors.lightBlueAccent;
    List<PlutoColumn> list = [];

    list.add(
      PlutoColumn(
        title: 'detail_id',
        field: 'detail_id',
        backgroundColor: colorHeader,
        readOnly: true,
        width: 145,
        minWidth: 145,
        type: PlutoColumnType.text(),
        hide: true,
      ),
    );
    list.add(
      PlutoColumn(
        title: 'outgoing_id',
        field: 'outgoing_id',
        backgroundColor: colorHeader,
        readOnly: true,
        width: 120,
        type: PlutoColumnType.text(),
        hide: true,
        enableHideColumnMenuItem: false,
        enableContextMenu: false,
        enableSetColumnsMenuItem: false,
      ),
    );
    list.add(
      PlutoColumn(
        title: 'Producto',
        field: 'supply_id',
        backgroundColor: colorHeader,
        readOnly: true,
        width: 200,
        textAlign: PlutoColumnTextAlign.start,
        type: PlutoColumnType.text(),
        enableHideColumnMenuItem: false,
        enableFilterMenuItem: false,
        enableContextMenu: false,
        enableSetColumnsMenuItem: false,
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
      ),
    );
    list.add(
      PlutoColumn(
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
      ),
    );
    list.add(
      PlutoColumn(
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
      ),
    );
    list.add(
      PlutoColumn(
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
      ),
    );
    list.add(
      PlutoColumn(
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
      ),
    );
    list.add(
      PlutoColumn(
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
      ),
    );

    list.add(
      PlutoColumn(
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
                    final rowIndex = rendererContext.rowIdx;
                    if (rowIndex < _details.length) {
                      _showDetailModal(rowIndex);
                    }
                  },
                  iconSize: 15,
                  padding: const EdgeInsets.all(0),
                ),
              ),
            ],
          );
        },
      ),
    );
    list.add(
      PlutoColumn(
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
                  icon: const Image(
                    image: AssetImage('assets/images/eliminar_32x32.png'),
                  ),
                  onPressed: () {
                    final rowIndex = rendererContext.rowIdx;
                    if (rowIndex < _details.length) {
                      final detailData = _lisDocumentDetails[rowIndex];
                      final detailId = detailData['detail_id'];

                      // NO permitir eliminar si ya está grabado en BD
                      if (detailId > 0) {
                        AwesomeDialog(
                          context: context,
                          animType: AnimType.bottomSlide,
                          dialogType: DialogType.warning,
                          title: 'Detalle No Eliminable',
                          desc: 'Este detalle ya está guardado en la base de datos y no puede ser eliminado.',
                          btnOkText: 'Entendido',
                          btnOkOnPress: () {},
                        ).show();
                        return;
                      }

                      // Solo eliminar si es un detalle nuevo (detail_id = 0)
                      _showDeleteConfirmation(rowIndex);
                    }
                  },
                  iconSize: 15,
                  padding: const EdgeInsets.all(0),
                ),
              ),
            ],
          );
        },
      ),
    );
    return list;
  }

  // Método para mostrar confirmación de eliminación
  void _showDeleteConfirmation(int index) {
    AwesomeDialog(
      context: context,
      animType: AnimType.bottomSlide,
      dialogType: DialogType.question,
      title: 'Confirmar Eliminación',
      desc: '¿Está seguro que desea eliminar este detalle?',
      btnCancelText: 'Cancelar',
      btnOkText: 'Eliminar',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        _removeDetail(index);
      },
    ).show();
  }

  // Método para mostrar modal de detalle
  void _showDetailModal([int? editIndex]) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return _buildDetailFormModal(editIndex);
      },
    );
  }

  // Construir el modal del formulario de detalle
  Widget _buildDetailFormModal([int? editIndex]) {
    final isEditing = editIndex != null;
    final detail = isEditing ? _details[editIndex] : OutgoingDetailForm();

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Editar Detalle' : 'Agregar Detalle',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 20),

              // Formulario del detalle
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Dropdown de Producto
                      _buildSupplyDropdownModal(detail, setModalState),
                      const SizedBox(height: 20),

                      // Cantidad y Costo Unitario
                      Row(
                        children: [
                          Expanded(child: _buildQuantityFieldModal(detail,setModalState,),),
                          const SizedBox(width: 20),
                          Expanded(child: _buildUnitCostFieldModal(detail,setModalState,),),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Subtotal (solo lectura) y Número de Lote
                      Row(
                        children: [
                          Expanded(child: _buildSubtotalFieldModal(detail)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildBatchNumberFieldModal(detail)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Notas
                      _buildNotesFieldModal(detail),
                    ],
                  ),
                ),
              ),

              // Botones de acción
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveDetailFromModal(detail, editIndex, context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(isEditing ? 'Actualizar' : 'Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Método para guardar detalle desde el modal
  void _saveDetailFromModal(
    OutgoingDetailForm detail,
    int? editIndex,
    BuildContext context,
  ) {
    // Validar campos requeridos
    if (detail.supplyId == 0) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Producto Requerido',
        desc: 'Por favor seleccione un producto',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    if (detail.quantityController.text.trim().isEmpty) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Cantidad Requerida',
        desc: 'Por favor ingrese la cantidad',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    if (detail.unitCostController.text.trim().isEmpty) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Costo Requerido',
        desc: 'Por favor ingrese el costo unitario',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    // Calcular subtotal final
    detail.calculateSubtotal();

    if (editIndex != null) {
      // Actualizar detalle existente
      setState(() {
        _details[editIndex] = detail;
      });
    } else {
      // Agregar nuevo detalle
      setState(() {
        _details.add(detail);
      });
    }

    // Cerrar modal y actualizar
    Navigator.pop(context);
    _calculateTotals();
    _syncDetailsWithGrid();
  }

  // Métodos para campos del modal
  Widget _buildSupplyDropdownModal(
    OutgoingDetailForm detail,
    StateSetter setModalState,
  ) {
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

    MasterSupply? selectedSupply;
    try {
      if (detail.supplyId > 0) {
        selectedSupply = _supplies.firstWhere(
          (supply) => supply.supplyId == detail.supplyId,
        );
      }
    } catch (e) {
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
          setModalState(() {
            detail.supplyId = newValue.supplyId ?? 0;
            detail.unitCost = newValue.unitCost;
            detail.unitCostController.text = detail.unitCost.toStringAsFixed(2);
            detail.calculateSubtotal();
          });
        }
      },
    );
  }

  Widget _buildQuantityFieldModal(
    OutgoingDetailForm detail,
    StateSetter setModalState,
  ) {
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
        final quantity = double.tryParse(value) ?? 0;
        if (quantity <= 0) {
          return 'La cantidad debe ser mayor a 0';
        }
        return null;
      },
      onChanged: (value) {
        setModalState(() {
          detail.calculateSubtotal();
        });
      },
    );
  }

  Widget _buildUnitCostFieldModal(
    OutgoingDetailForm detail,
    StateSetter setModalState,
  ) {
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
          return 'Ingrese el costo';
        }
        if (double.tryParse(value) == null) {
          return 'Ingrese un número válido';
        }
        final cost = double.tryParse(value) ?? 0;
        if (cost < 0) {
          return 'El costo no puede ser negativo';
        }
        return null;
      },
      onChanged: (value) {
        setModalState(() {
          detail.calculateSubtotal();
        });
      },
    );
  }

  Widget _buildSubtotalFieldModal(OutgoingDetailForm detail) {
    return TextFormField(
      controller: detail.subtotalController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Subtotal',
        prefixText: '\$ ',
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        filled: true,
        fillColor: Colors.grey.shade200,
      ),
    );
  }

  Widget _buildBatchNumberFieldModal(OutgoingDetailForm detail) {
    return TextFormField(
      controller: detail.batchNumberController,
      maxLength: 50,
      textCapitalization: TextCapitalization.sentences,
      inputFormatters: [UpperCaseTextFormatter()],
      keyboardType: TextInputType.text,
      style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w500),      
      decoration: const InputDecoration(
        labelText: 'Número de Lote',
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  Widget _buildNotesFieldModal(OutgoingDetailForm detail) {
    return TextFormField(
      controller: detail.notesController,
      maxLines: 2,
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

  void _loadTransactionData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is int && args > 0) {
      _transactionId = args;
      _isEditing = true;
      _loadTransaction();
    } else {
      _transactionNumberController.text = OutgoingTransactionService.generateTransactionNumber();
      _transactionDateController.text = DateTime.now().toIso8601String().split('T',)[0];
      //_addDetail();
    }
  }

  Future<void> _loadTransaction() async {
    if (_transactionId == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final tx = await OutgoingTransactionService.getOutgoingTransactionById(
        _transactionId!,
      );
      if (tx != null) {
        setState(() {
          _transactionNumberController.text = tx.transactionNumber;
          _transactionDateController.text = tx.transactionDate;
          _reasonController.text = tx.reason;
          _totalController.text = tx.total.toString();
          _selectedTransactionType = tx.transactionType;
          _selectedStatus = tx.status;
          _patientIdController.text = tx.patientId.toString();
          _dentistIdController.text = tx.dentistId.toString();

          _details.clear();
          for (var d in tx.details) {
            final df = OutgoingDetailForm();
            df.detailId = d.detailId;
            df.supplyId = d.supplyId;
            df.quantity = d.quantity;
            df.unitCost = d.unitCost;
            df.subtotal = d.subtotal;
            df.quantityController.text = d.quantity.toString();
            df.unitCostController.text = d.unitCost.toString();
            df.subtotalController.text = d.subtotal.toStringAsFixed(2);
            df.batchNumberController.text = d.batchNumber;
            df.notesController.text = d.notes;
            _details.add(df);
          }

          // Sincronizar con grid después de cargar detalles
          _syncDetailsWithGrid();

          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              _limpiarFormulario();
            },
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Editar Transacción de Egreso'
              : 'Nueva Transacción de Egreso',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: ButtonBack(),
        actions: [AppBarConnectionStatus()],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _isLoading || _isLoadingDropdowns
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: 
                    [
                      _buildHeaderSection(), 

                      _buildDetailsSection()
                    ],
                  ),
                ),
              ),
            ),
    );
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
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Información de Cabecera',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                ResponsiveGridRow(
                  children: [
                    ResponsiveGridCol(
                      lg: 3,
                      xl: 3,
                      md: 3,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildTransactionNumberField(),
                      ),
                    ),
                    ResponsiveGridCol(
                      lg: 3,
                      xl: 3,
                      md: 3,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildTransactionDateField(),
                      ),
                    ),
                    ResponsiveGridCol(
                      lg: 3,
                      xl: 3,
                      md: 3,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildTransactionTypeDropdown(),
                      ),
                    ),                    
                    ResponsiveGridCol(
                      lg: 3,
                      xl: 3,
                      md: 3,
                      sm: 12,
                      xs: 12,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: _buildStatusDropdown(),
                      ),
                    ),                    
                  ],
                ),
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
                        child: _buildPatientIdField(),
                      ),
                    ),
                    ResponsiveGridCol(
                      lg: 3,
                      xl: 3,
                      md: 3,
                      sm: 11,
                      xs: 11,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDentistIdField(),
                            if (_isLoadingDropdowns)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Cargando dentistas...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    ResponsiveGridCol(
                      lg: 1,
                      xl: 1,
                      md: 1,
                      sm: 1,
                      xs: 1,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        child: IconButton(
                          onPressed: _reloadDentists,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Recargar dentistas',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
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
                        child: _buildReasonField(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
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
                        onRowDoubleTap:
                            (PlutoGridOnRowDoubleTapEvent event) async {},
                        configuration: PlutoGridConfiguration(
                          style: const PlutoGridStyleConfig(
                            enableColumnBorderHorizontal: true,
                            enableCellBorderVertical: true,
                            enableGridBorderShadow: true,
                          ),
                          columnFilter: const PlutoGridColumnFilterConfig(),
                          columnSize: PlutoGridColumnSizeConfig(
                            autoSizeMode: isSmallScreen
                                ? PlutoAutoSizeMode.none
                                : PlutoAutoSizeMode.scale,
                            resizeMode: isSmallScreen
                                ? PlutoResizeMode.normal
                                : PlutoResizeMode.none,
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

  // Campos cabecera
  TextFormField _buildTransactionNumberField() => TextFormField(
    controller: _transactionNumberController,
    readOnly: _isEditing,
    decoration: const InputDecoration(
      labelText: 'Número de Transacción *',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
    ),
    validator: (v) {
      if (v == null || v.trim().isEmpty) {
        return 'Ingrese el número de transacción';
      }
      return null;
    },
  );
  
  TextFormField _buildTransactionDateField() => TextFormField(
    controller: _transactionDateController,
    readOnly: true,
    decoration: const InputDecoration(
      labelText: 'Fecha de Transacción *',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
    ),
    validator: (v) {
      if (v == null || v.trim().isEmpty) {
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
          String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
          setState(() {
            _transactionDateController.text = formattedDate;
          });
        } else {
          _transactionDateController.clear();
        }
      },     
  );

  DropdownButtonFormField<String> _buildTransactionTypeDropdown() =>
      DropdownButtonFormField<String>(
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
      
  DropdownButtonFormField<String> _buildStatusDropdown() =>
      DropdownButtonFormField<String>(
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
      
  TextFormField _buildPatientIdField() => TextFormField(
    controller: _patientIdController,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      labelText: 'Paciente ID *',
      suffixIcon: Icon(Icons.search),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
    ),
    validator: (v) {
      if (v == null || v.trim().isEmpty) return 'Ingrese Paciente ID';
      if (int.tryParse(v) == null) return 'Ingrese un número válido';
      return null;
    },
    onTap: () {
      if (_patientIdController.text.isNotEmpty) {
        //_searchPatient();
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.info,
          title: 'Información',
          desc: 'Ingrese el ID (Cédula) del paciente para buscar',
          btnOkText: 'Entendido',
          btnOkOnPress: () {},
        ).show();
      }
    },
  );
  
  DropdownButtonFormField<String> _buildDentistIdField() =>
      DropdownButtonFormField<String>(
        value: _selectedDentist,
        decoration: InputDecoration(
          labelText: 'Doctor(a) *',
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          suffixIcon: _isLoadingDropdowns 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
        ),
        items: _dentists.map((dentist) { 
          return DropdownMenuItem<String>(
          value: dentist['codigo'],
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dentist['descripcion'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
        );
      }).toList(),
      onChanged: _isLoadingDropdowns ? null : (String? newValue) {
        setState(() {
          _selectedDentist = newValue!;
        });
      },
      );

  TextFormField _buildReasonField() => TextFormField(
    controller: _reasonController,
    maxLines: 2,
    maxLength: 400,
    decoration: const InputDecoration(
      labelText: 'Motivo *',
      hintText: 'Ingrese el motivo de la transacción',
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
    ),
    validator: (v) {
      if (v == null || v.trim().isEmpty) return 'Ingrese el motivo';
      return null;
    },
  );
  
  TextFormField _buildTotalField() => TextFormField(
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


  void _addDetail() {
    // Mostrar modal para agregar detalle
    _showDetailModal();
  }

  void _removeDetail(int index) {
    setState(() => _details.removeAt(index));
    _calculateTotals();
    _syncDetailsWithGrid();
  }

  void _calculateTotals() {
    double total = 0;
    for (final d in _details) {
      total += d.subtotal;
    }
    _totalController.text = total.toStringAsFixed(2);
    _syncDetailsWithGrid();
  }

  void _limpiarFormulario() {
    _transactionNumberController.clear();
    _transactionDateController.clear();
    _reasonController.clear();
    _totalController.clear();
    _patientIdController.clear();
    _dentistIdController.clear();
    setState(() {
      _selectedTransactionType = 'CONSUMPTION';
      _selectedStatus = 'PENDING';
      _selectedDentist = '0';
      _details.clear();
    });
    _transactionNumberController.text =
        OutgoingTransactionService.generateTransactionNumber();
    _transactionDateController.text = DateTime.now().toIso8601String().split(
      'T',
    )[0];
    _addDetail();
    _syncDetailsWithGrid();
  }

  Future<void> _guardarTransaccion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_details.isEmpty) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Detalles Requeridos',
        desc: 'Debe agregar al menos un detalle',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(
      max: 600,
      msg: _isEditing ? 'Actualizando egreso...' : 'Guardando egreso...',
    );
    try {
      final details = _details
          .map(
            (d) => CreateOutgoingDetail(
              supplyId: d.supplyId,
              quantity: d.quantity,
              unitCost: d.unitCost,
              subtotal: d.subtotal,
              batchNumber: d.batchNumber,
              notes: d.notes,
            ),
          )
          .toList();
      if (_isEditing) {
        final tx = OutgoingTransaction(
          outgoingId: _transactionId,
          transactionNumber: _transactionNumberController.text.trim(),
          transactionDate: _transactionDateController.text.trim(),
          transactionType: _selectedTransactionType,
          patientId: int.parse(_patientIdController.text.trim()),
          dentistId: int.parse(_dentistIdController.text.trim()),
          reason: _reasonController.text.trim(),
          total: double.parse(_totalController.text.trim()),
          status: _selectedStatus,
          details: details
              .map(
                (d) => OutgoingDetail(
                  supplyId: d.supplyId,
                  quantity: d.quantity,
                  unitCost: d.unitCost,
                  subtotal: d.subtotal,
                  batchNumber: d.batchNumber,
                  notes: d.notes,
                ),
              )
              .toList(),
        );
        await OutgoingTransactionService.updateOutgoingTransaction(tx);
      } else {
        final tx = CreateOutgoingTransaction(
          transactionNumber: _transactionNumberController.text.trim(),
          transactionDate: _transactionDateController.text.trim(),
          transactionType: _selectedTransactionType,
          patientId: int.parse(_patientIdController.text.trim()),
          dentistId: int.parse(_dentistIdController.text.trim()),
          reason: _reasonController.text.trim(),
          total: double.parse(_totalController.text.trim()),
          details: details,
        );
        await OutgoingTransactionService.createOutgoingTransaction(tx);
      }
      pr.close();
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.success,
          title: 'Éxito',
          desc: _isEditing
              ? 'Egreso actualizado correctamente'
              : 'Egreso creado correctamente',
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
          desc: 'Error al guardar el egreso: $e',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }
}

class OutgoingDetailForm {
  int? detailId; // ID del detalle en BD (null = nuevo, >0 = existente)
  int supplyId = 0;
  double quantity = 0;
  double unitCost = 0;
  double subtotal = 0;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitCostController = TextEditingController();
  final TextEditingController subtotalController = TextEditingController();
  final TextEditingController batchNumberController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // Constructor por defecto
  OutgoingDetailForm() {
    detailId = null;
    supplyId = 0;
    quantity = 0;
    unitCost = 0;
    subtotal = 0;
    
    // Inicializar controladores con valores por defecto
    quantityController.text = '';
    unitCostController.text = '0.00';
    subtotalController.text = '0.00';
    batchNumberController.text = '';
    notesController.text = '';
  }

  // Constructor para detalles existentes
  OutgoingDetailForm.fromExisting({
    required this.detailId,
    required this.supplyId,
    required this.quantity,
    required this.unitCost,
    required this.subtotal,
    String? batchNumber,
    String? notes,
  }) {
    quantityController.text = quantity.toString();
    unitCostController.text = unitCost.toStringAsFixed(2);
    subtotalController.text = subtotal.toStringAsFixed(2);
    batchNumberController.text = batchNumber ?? '';
    notesController.text = notes ?? '';
  }

  void calculateSubtotal() {
    quantity = double.tryParse(quantityController.text) ?? 0;
    unitCost = double.tryParse(unitCostController.text) ?? 0;
    subtotal = quantity * unitCost;
    subtotalController.text = subtotal.toStringAsFixed(2);
  }

  String get batchNumber => batchNumberController.text.trim();
  String get notes => notesController.text.trim();

  // Método para limpiar controladores
  void dispose() {
    quantityController.dispose();
    unitCostController.dispose();
    subtotalController.dispose();
    batchNumberController.dispose();
    notesController.dispose();
  }
}
