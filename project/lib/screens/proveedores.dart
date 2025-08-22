/* Autor: Pio enrique Olvera Briones
   Fecha: 07/08/2025
   Descripción: pantalla para gestión de proveedores
*/

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:button_navigation_bar/button_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'package:odontologo/services/supplier_service.dart';
import 'package:odontologo/object/supplier.dart';
import 'package:odontologo/widgets/connection_status.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

class Proveedores extends StatefulWidget {
  const Proveedores({super.key});

  @override
  State<Proveedores> createState() => _ProveedoresState();
}

class _ProveedoresState extends State<Proveedores> {
  final _formKey = GlobalKey<FormState>();
  PlutoGridStateManager? stateManager;
  final List<Supplier> _suppliers = [];
  List<PlutoColumn> columns = [];
  final _buscarProveedorController = TextEditingController();
  String _verticalGroupValue = "Código";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    columns = _columnsRender();
    //_loadSuppliers();
  }

  @override
  void dispose() {
    _buscarProveedorController.dispose();
    super.dispose();
  }

  bool esPantallaGrande(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      floatingActionButton: ButtonNavigationBar(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        children: [
          ButtonNavigationItem(
            label: " Nuevo",
            height: 40,
            width: 130,
            icon: const Icon(Icons.add_business, color: Colors.white),
            color: Colors.blue[200],
            onPressed: () async {
              Navigator.pushNamed(context, '/proveedor', arguments: 0);
            },
          ),
          ButtonNavigationItem(
            label: " Editar",
            height: 40,
            width: 130,
            icon: const Icon(Icons.edit, color: Colors.white),
            color: Colors.orange[200],
            onPressed: () async {
              await _editarProveedor();
            },
          ),
          ButtonNavigationItem(
            label: " Eliminar",
            height: 40,
            width: 130,
            icon: const Icon(Icons.delete_forever_outlined, color: Colors.white),
            color: Colors.red[200],
            onPressed: () async {
              await _eliminarProveedor();
            },
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text(
          'Gestión de Proveedores',
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
            onPressed: _loadSuppliers,
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
                                    items: ["Código", "Nombre", "Razón Social"],
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
                                    child: _buildBuscarProveedor(context),
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
                    // Tabla de proveedores
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
                                              rows: rowsLista(_suppliers),
                                              mode: PlutoGridMode.normal,
                                              onLoaded: (PlutoGridOnLoadedEvent event) {
                                                stateManager = event.stateManager;
                                                stateManager?.setKeepFocus(false);
                                                event.stateManager.setShowColumnFilter(true);
                                                event.stateManager.setShowColumnFooter(false);
                                              },
                                              onChanged: (event) {},
                                              onRowDoubleTap: (event) {
                                                _editarProveedorSeleccionado(event.row);
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
          await _buscarProveedores();
        },
        icon: const Icon(Icons.search_rounded, color: Colors.white70),
      ),
    );
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final suppliers = await SupplierService.getAllSuppliers();
      setState(() {
        _suppliers.clear();
        _suppliers.addAll(suppliers);
        _isLoading = false;
      });
      
      if (stateManager?.rows.isNotEmpty == true) {
        stateManager?.removeRows(stateManager!.rows);
      }
      stateManager?.appendRows(rowsLista(_suppliers));
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
          desc: 'Error al cargar proveedores: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  Future<void> _buscarProveedores() async {
    final query = _buscarProveedorController.text.trim();
    if (query.isEmpty) {
      //await _loadSuppliers();
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.warning,
          title: 'Aviso',
          desc: 'Ingrese un valor para buscar',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String filterField = "id";

    if (_verticalGroupValue == "Código") {
      filterField = "code";
    } else if (_verticalGroupValue == "Nombre") {
      filterField = "name";
    } else if (_verticalGroupValue == "Razón Social") {
      filterField = "business_name";
    }

    try {
      final suppliers = await SupplierService.searchSuppliers(query, filterField);
      setState(() {
        _suppliers.clear();
        _suppliers.addAll(suppliers);
        _buscarProveedorController.clear();
        _isLoading = false;
      });
      
      if (stateManager?.rows.isNotEmpty == true) {
        stateManager?.removeRows(stateManager!.rows);
      }
      stateManager?.appendRows(rowsLista(_suppliers));
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

  TextFormField _buildBuscarProveedor(BuildContext context) {
    return TextFormField(
      controller: _buscarProveedorController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 100,
      decoration: const InputDecoration(
        labelText: 'Buscar proveedor...',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  List<PlutoRow> rowsLista(List<Supplier> suppliers) {
    List<PlutoRow> retorno = [];
    try {
      for (var supplier in suppliers) {
        retorno.add(
          PlutoRow(
            cells: {
              'Seleccion': PlutoCell(value: false),
              'Código': PlutoCell(value: supplier.code),
              'Nombre': PlutoCell(value: supplier.name),
              'Razón Social': PlutoCell(value: supplier.businessName),
              'RUC': PlutoCell(value: supplier.taxId),
              'Dirección': PlutoCell(value: supplier.address),
              'Teléfono': PlutoCell(value: supplier.phone),
              'Email': PlutoCell(value: supplier.email),
              'Contacto': PlutoCell(value: supplier.mainContact),
              'ID': PlutoCell(value: supplier.supplierId),
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

    // Código
    list.add(
      PlutoColumn(
        title: 'Código',
        field: 'Código',
        backgroundColor: colorHeader,
        width: 120,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
        renderer: (rendererContext) {
          final code = rendererContext.cell.value;
          return Tooltip(
            message: 'Editar Proveedor',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  final int supplierId = rendererContext.row.cells['ID']?.value;
                  Navigator.pushNamed(context, '/proveedor', arguments: supplierId);
                },
                child: Text(
                  code,
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

    // Nombre
    list.add(
      PlutoColumn(
        title: 'Nombre',
        field: 'Nombre',
        backgroundColor: colorHeader,
        width: 200,
        textAlign: PlutoColumnTextAlign.left,
        type: PlutoColumnType.text(),
      ),
    );

    // Razón Social
    list.add(
      PlutoColumn(
        title: 'Razón Social',
        field: 'Razón Social',
        backgroundColor: colorHeader,
        width: 250,
        textAlign: PlutoColumnTextAlign.left,
        type: PlutoColumnType.text(),
      ),
    );

    // RUC
    list.add(
      PlutoColumn(
        title: 'RUC',
        field: 'RUC',
        backgroundColor: colorHeader,
        width: 120,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
      ),
    );

    // Dirección
    list.add(
      PlutoColumn(
        title: 'Dirección',
        field: 'Dirección',
        backgroundColor: colorHeader,
        width: 250,
        textAlign: PlutoColumnTextAlign.left,
        type: PlutoColumnType.text(),
      ),
    );

    // Teléfono
    list.add(
      PlutoColumn(
        title: 'Teléfono',
        field: 'Teléfono',
        backgroundColor: colorHeader,
        width: 150,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
      ),
    );

    // Email
    list.add(
      PlutoColumn(
        title: 'Email',
        field: 'Email',
        backgroundColor: colorHeader,
        width: 200,
        textAlign: PlutoColumnTextAlign.left,
        type: PlutoColumnType.text(),
      ),
    );

    // Contacto Principal
    list.add(
      PlutoColumn(
        title: 'Contacto',
        field: 'Contacto',
        backgroundColor: colorHeader,
        width: 150,
        textAlign: PlutoColumnTextAlign.left,
        type: PlutoColumnType.text(),
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

  Future<void> _editarProveedor() async {
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
        desc: 'Por favor seleccione un proveedor para editar',
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
        desc: 'Por favor seleccione solo un proveedor para editar',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    final selectedRow = selectedRows.first;
    final supplierId = selectedRow.cells['ID']?.value as int?;
    
    if (supplierId != null) {
      Navigator.pushNamed(context, '/proveedor', arguments: supplierId);
    }
  }

  void _editarProveedorSeleccionado(PlutoRow row) {
    final supplierId = row.cells['ID']?.value as int?;
    if (supplierId != null) {
      Navigator.pushNamed(context, '/proveedor', arguments: supplierId);
    }
  }

  Future<void> _eliminarProveedor() async {
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
        desc: 'Por favor seleccione un proveedor para eliminar',
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
        desc: 'Por favor seleccione solo un proveedor para eliminar',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    final selectedRow = selectedRows.first;
    final supplierId = selectedRow.cells['ID']?.value as int?;
    final supplierName = selectedRow.cells['Nombre']?.value as String?;
    
    if (supplierId == null) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.error,
        title: 'Error',
        desc: 'No se pudo obtener el ID del proveedor',
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
      desc: '¿Está seguro que desea eliminar al proveedor:\n\n$supplierName?\n\nEsta acción no se puede deshacer.',
      btnOkText: 'ELIMINAR',
      btnOkColor: Colors.red,
      btnOkOnPress: () async {
        await _ejecutarEliminacion(supplierId, supplierName ?? '');
      },
      btnCancelText: 'CANCELAR',
      btnCancelOnPress: () {},
    ).show();
  }

  Future<void> _ejecutarEliminacion(int supplierId, String supplierName) async {
    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: 'Eliminando proveedor...');

    try {
      final success = await SupplierService.deleteSupplier(supplierId);
      pr.close();

      if (success) {
        if (mounted) {
          AwesomeDialog(
            context: context,
            animType: AnimType.bottomSlide,
            dialogType: DialogType.success,
            title: 'Eliminación Exitosa',
            desc: 'El proveedor $supplierName ha sido eliminado correctamente.',
            btnOkText: 'Aceptar',
            btnOkOnPress: () {
              _loadSuppliers();
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
          desc: 'Error al eliminar el proveedor: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

} 