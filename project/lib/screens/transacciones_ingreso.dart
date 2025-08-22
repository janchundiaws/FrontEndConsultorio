/* Autor: Pio enrique Olvera Briones
   Fecha: 07/08/2025
   Descripción: pantalla para gestión de transacciones de ingreso de insumos
*/

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:button_navigation_bar/button_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'package:odontologo/services/incoming_transaction_service.dart';
import 'package:odontologo/object/incoming_transaction.dart';
import 'package:odontologo/widgets/connection_status.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

class TransaccionesIngreso extends StatefulWidget {
  const TransaccionesIngreso({super.key});

  @override
  State<TransaccionesIngreso> createState() => _TransaccionesIngresoState();
}

class _TransaccionesIngresoState extends State<TransaccionesIngreso> {
  final _formKey = GlobalKey<FormState>();
  PlutoGridStateManager? stateManager;
  final List<IncomingTransaction> _transactions = [];
  List<PlutoColumn> columns = [];
  final _buscarTransaccionController = TextEditingController();
  String _verticalGroupValue = "Número Transacción";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    columns = _columnsRender();
    _loadTransactions();
  }

  @override
  void dispose() {
    _buscarTransaccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      floatingActionButton: ButtonNavigationBar(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        children: [
          ButtonNavigationItem(
            label: " Nueva",
            height: 40,
            width: 130,
            icon: const Icon(Icons.add_box, color: Colors.white),
            color: Colors.blue[200],
            onPressed: () async {
              Navigator.pushNamed(context, '/transaccion_ingreso', arguments: 0);
            },
          ),
          ButtonNavigationItem(
            label: " Ver",
            height: 40,
            width: 130,
            icon: const Icon(Icons.visibility, color: Colors.white),
            color: Colors.green[200],
            onPressed: () async {
              await _verTransaccion();
            },
          ),
          ButtonNavigationItem(
            label: " Eliminar",
            height: 40,
            width: 130,
            icon: const Icon(Icons.delete_forever_outlined, color: Colors.white),
            color: Colors.red[200],
            onPressed: () async {
              await _eliminarTransaccion();
            },
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text(
          'Transacciones de Ingreso',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: ButtonBack(),
        actions: [
          AppBarConnectionStatus(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Sección de búsqueda
                    Container(
                      padding: const EdgeInsets.all(5),
                      margin: const EdgeInsets.all(10),
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
                                  lg: 8,
                                  xl: 8,
                                  md: 8,
                                  sm: 10,
                                  xs: 10,
                                  child: RadioGroup<String>.builder(
                                    direction: Axis.horizontal,
                                    groupValue: _verticalGroupValue,
                                    horizontalAlignment: MainAxisAlignment.spaceBetween,
                                    onChanged: (value) => setState(() {
                                      _verticalGroupValue = value ?? '';
                                    }),
                                    items: ["Número Transacción", "Número Factura", "Proveedor"],
                                    itemBuilder: (item) => RadioButtonBuilder(
                                      item,
                                      textPosition: RadioButtonTextPosition.right,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            ResponsiveGridRow(
                              children: [
                                ResponsiveGridCol(
                                  lg: 8,
                                  xl: 8,
                                  md: 8,
                                  sm: 8,
                                  xs: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(3.0),
                                    child: _buildBuscarTransaccion(context),
                                  ),
                                ),
                                ResponsiveGridCol(
                                  lg: 1,
                                  xl: 1,
                                  md: 1,
                                  sm: 1,
                                  xs: 1,
                                  child: SizedBox(),
                                ),
                                ResponsiveGridCol(
                                  lg: 3,
                                  xl: 3,
                                  md: 3,
                                  sm: 3,
                                  xs: 3,
                                  child: btnBuscar(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tabla de transacciones
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
                                      child: _isLoading
                                          ? const Center(child: CircularProgressIndicator())
                                          : PlutoGrid(
                                              columns: columns,
                                              rows: rowsLista(_transactions),
                                              mode: PlutoGridMode.normal,
                                              onLoaded: (PlutoGridOnLoadedEvent event) {
                                                stateManager = event.stateManager;
                                                stateManager?.setKeepFocus(false);
                                                stateManager?.setShowColumnFilter(true);
                                                stateManager?.setShowColumnFooter(false);
                                              },
                                              onChanged: (event) {},
                                              onRowDoubleTap: (event) {
                                                _verTransaccionSeleccionada(event.row);
                                              },
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
          ),
        ],
      ),
    );
  }

  Container btnBuscar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
      child: ElevatedButton.icon(
        label: const Text(
          "Buscar",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(Colors.lightBlue),
          padding: WidgetStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          ),
        ),
        onPressed: () async {
          await _buscarTransacciones();
        },
        icon: const Icon(Icons.search_rounded, color: Colors.white70),
      ),
    );
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await IncomingTransactionService.getAllIncomingTransactions();
      setState(() {
        _transactions.clear();
        _transactions.addAll(transactions);
        _isLoading = false;
      });
      
      if (stateManager?.rows.isNotEmpty == true) {
        stateManager?.removeRows(stateManager!.rows);
      }
      stateManager?.appendRows(rowsLista(_transactions));
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
          desc: 'Error al cargar transacciones: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  Future<void> _buscarTransacciones() async {
    final query = _buscarTransaccionController.text.trim();
    if (query.isEmpty) {
      await _loadTransactions();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await IncomingTransactionService.searchIncomingTransactions(query);
      setState(() {
        _transactions.clear();
        _transactions.addAll(transactions);
        _isLoading = false;
      });
      
      if (stateManager?.rows.isNotEmpty == true) {
        stateManager?.removeRows(stateManager!.rows);
      }
      stateManager?.appendRows(rowsLista(_transactions));
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
          desc: 'Error en la búsqueda: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  TextFormField _buildBuscarTransaccion(BuildContext context) {
    return TextFormField(
      controller: _buscarTransaccionController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 100,
      decoration: const InputDecoration(
        labelText: 'Buscar transacción...',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  List<PlutoRow> rowsLista(List<IncomingTransaction> transactions) {
    List<PlutoRow> retorno = [];
    try {
      for (var transaction in transactions) {
        retorno.add(
          PlutoRow(
            cells: {
              'Seleccion': PlutoCell(value: false),
              'Número': PlutoCell(value: transaction.transactionNumber),
              'Fecha': PlutoCell(value: transaction.transactionDate),
              'Proveedor ID': PlutoCell(value: transaction.supplierId),
              'Factura': PlutoCell(value: transaction.invoiceNumber),
              'Tipo': PlutoCell(value: transaction.transactionType),
              'Subtotal': PlutoCell(value: transaction.subtotal.toStringAsFixed(2)),
              'Impuestos': PlutoCell(value: transaction.taxAmount.toStringAsFixed(2)),
              'Total': PlutoCell(value: transaction.total.toStringAsFixed(2)),
              'Estado': PlutoCell(value: transaction.status),
              'Detalles': PlutoCell(value: transaction.details.length),
              'ID': PlutoCell(value: transaction.incomingId),
            },
          ),
        );
      }
    } on Exception catch (e) {
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
    return retorno;
  }

  List<PlutoColumn> _columnsRender() {
    Color colorHeader = Colors.lightBlue;
    List<PlutoColumn> list = [];

    // Columna de selección
    list.add(
      PlutoColumn(
        title: '',
        field: 'Seleccion',
        backgroundColor: colorHeader,
        readOnly: false,
        width: 50,
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

    // Número de Transacción
    list.add(
      PlutoColumn(
        title: 'Número',
        field: 'Número',
        backgroundColor: colorHeader,
        width: 150,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
        renderer: (rendererContext) {
          final numero = rendererContext.cell.value;
          return Tooltip(
            message: 'Ver Transacción',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  final int transactionId = rendererContext.row.cells['ID']?.value;
                  Navigator.pushNamed(context, '/transaccion_ingreso', arguments: transactionId);
                },
                child: Text(
                  numero,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    // Fecha
    list.add(
      PlutoColumn(
        title: 'Fecha',
        field: 'Fecha',
        backgroundColor: colorHeader,
        width: 120,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
      ),
    );

    // Proveedor ID
    list.add(
      PlutoColumn(
        title: 'Proveedor ID',
        field: 'Proveedor ID',
        backgroundColor: colorHeader,
        width: 100,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.number(),
      ),
    );

    // Número de Factura
    list.add(
      PlutoColumn(
        title: 'Factura',
        field: 'Factura',
        backgroundColor: colorHeader,
        width: 120,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
      ),
    );

    // Tipo de Transacción
    list.add(
      PlutoColumn(
        title: 'Tipo',
        field: 'Tipo',
        backgroundColor: colorHeader,
        width: 100,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
        renderer: (rendererContext) {
          final tipo = rendererContext.cell.value;
          Color color;
          switch (tipo) {
            case 'PURCHASE':
              color = Colors.blue;
              break;
            case 'DONATION':
              color = Colors.green;
              break;
            case 'RETURN':
              color = Colors.orange;
              break;
            default:
              color = Colors.grey;
          }
          
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tipo,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );

    // Subtotal
    list.add(
      PlutoColumn(
        title: 'Subtotal',
        field: 'Subtotal',
        backgroundColor: colorHeader,
        width: 100,
        textAlign: PlutoColumnTextAlign.right,
        type: PlutoColumnType.number(),
      ),
    );

    // Impuestos
    list.add(
      PlutoColumn(
        title: 'Impuestos',
        field: 'Impuestos',
        backgroundColor: colorHeader,
        width: 100,
        textAlign: PlutoColumnTextAlign.right,
        type: PlutoColumnType.number(),
      ),
    );

    // Total
    list.add(
      PlutoColumn(
        title: 'Total',
        field: 'Total',
        backgroundColor: colorHeader,
        width: 100,
        textAlign: PlutoColumnTextAlign.right,
        type: PlutoColumnType.number(),
      ),
    );

    // Estado
    list.add(
      PlutoColumn(
        title: 'Estado',
        field: 'Estado',
        backgroundColor: colorHeader,
        width: 100,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
        renderer: (rendererContext) {
          final estado = rendererContext.cell.value;
          Color color;
          switch (estado) {
            case 'APPROVED':
              color = Colors.green;
              break;
            case 'PENDING':
              color = Colors.orange;
              break;
            case 'REJECTED':
              color = Colors.red;
              break;
            default:
              color = Colors.grey;
          }
          
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              estado,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );

    // Cantidad de Detalles
    list.add(
      PlutoColumn(
        title: 'Detalles',
        field: 'Detalles',
        backgroundColor: colorHeader,
        width: 80,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.number(),
      ),
    );

    // ID (oculto)
    list.add(
      PlutoColumn(
        title: 'ID',
        field: 'ID',
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
        hide: true,
      ),
    );

    return list;
  }

  Future<void> _verTransaccion() async {
    final selectedRows = stateManager?.rows.where((row) {
      final isSelected = row.cells['Seleccion']?.value;
      return isSelected == true || isSelected == 'true';
    }).toList();

    if (selectedRows == null || selectedRows.isEmpty) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Selección Requerida',
        desc: 'Por favor seleccione una transacción para ver',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    if (selectedRows.length > 1) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Múltiples Selecciones',
        desc: 'Por favor seleccione solo una transacción para ver',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    final selectedRow = selectedRows.first;
    final transactionId = selectedRow.cells['ID']?.value as int?;
    
    if (transactionId != null) {
      Navigator.pushNamed(context, '/transaccion_ingreso', arguments: transactionId);
    }
  }

  void _verTransaccionSeleccionada(PlutoRow row) {
    final transactionId = row.cells['ID']?.value as int?;
    if (transactionId != null) {
      Navigator.pushNamed(context, '/transaccion_ingreso', arguments: transactionId);
    }
  }

  Future<void> _eliminarTransaccion() async {
    final selectedRows = stateManager?.rows.where((row) {
      final isSelected = row.cells['Seleccion']?.value;
      return isSelected == true || isSelected == 'true';
    }).toList();

    if (selectedRows == null || selectedRows.isEmpty) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Selección Requerida',
        desc: 'Por favor seleccione una transacción para eliminar',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    if (selectedRows.length > 1) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Múltiples Selecciones',
        desc: 'Por favor seleccione solo una transacción para eliminar',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    final selectedRow = selectedRows.first;
    final transactionId = selectedRow.cells['ID']?.value as int?;
    final transactionNumber = selectedRow.cells['Número']?.value as String?;
    
    if (transactionId == null) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.error,
        title: 'Error',
        desc: 'No se pudo obtener el ID de la transacción',
        btnOkText: 'Cerrar',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    // Confirmación final antes de eliminar
    AwesomeDialog(
      context: context,
      animType: AnimType.bottomSlide,
      dialogType: DialogType.warning,
      title: 'Confirmar Eliminación',
      desc: '¿Está seguro que desea eliminar la transacción:\n\n$transactionNumber?\n\nEsta acción no se puede deshacer.',
      btnOkText: 'ELIMINAR',
      btnOkColor: Colors.red,
      btnOkOnPress: () async {
        await _ejecutarEliminacion(transactionId, transactionNumber ?? '');
      },
      btnCancelText: 'CANCELAR',
      btnCancelOnPress: () {},
    ).show();
  }

  Future<void> _ejecutarEliminacion(int transactionId, String transactionNumber) async {
    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: 'Eliminando transacción...');

    try {
      final success = await IncomingTransactionService.deleteIncomingTransaction(transactionId);
      pr.close();

      if (success) {
        if (mounted) {
          AwesomeDialog(
            context: context,
            animType: AnimType.bottomSlide,
            dialogType: DialogType.success,
            title: 'Eliminación Exitosa',
            desc: 'La transacción $transactionNumber ha sido eliminada correctamente.',
            btnOkText: 'Aceptar',
            btnOkOnPress: () {
              _loadTransactions();
            },
          ).show();
        }
      }
    } catch (e) {
      pr.close();
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'Error al eliminar la transacción: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }
} 