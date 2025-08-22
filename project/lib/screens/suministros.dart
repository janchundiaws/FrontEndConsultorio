/* Autor: Pio enrique Olvera Briones
   Fecha: 07/08/2025
   Descripción: pantalla para gestión de maestros de suministros
*/

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:button_navigation_bar/button_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'package:odontologo/services/master_supply_service.dart';
import 'package:odontologo/object/master_supply.dart';
import 'package:odontologo/widgets/connection_status.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

class Suministros extends StatefulWidget {
  const Suministros({super.key});

  @override
  State<Suministros> createState() => _SuministrosState();
}

class _SuministrosState extends State<Suministros> {
  final _formKey = GlobalKey<FormState>();
  PlutoGridStateManager? stateManager;
  final List<MasterSupply> _supplies = [];
  List<PlutoColumn> columns = [];
  final _buscarSuministroController = TextEditingController();
  String _verticalGroupValue = "Código";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    columns = _columnsRender();
    //_loadSupplies();
  }

  @override
  void dispose() {
    _buscarSuministroController.dispose();
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
            icon: const Icon(Icons.add_box, color: Colors.white),
            color: Colors.blue[200],
            onPressed: () async {
              Navigator.pushNamed(context, '/suministro', arguments: 0);
            },
          ),
          ButtonNavigationItem(
            label: " Editar",
            height: 40,
            width: 130,
            icon: const Icon(Icons.edit, color: Colors.white),
            color: Colors.orange[200],
            onPressed: () async {
              await _editarSuministro();
            },
          ),
          ButtonNavigationItem(
            label: " Eliminar",
            height: 40,
            width: 130,
            icon: const Icon(Icons.delete_forever_outlined, color: Colors.white),
            color: Colors.red[200],
            onPressed: () async {
              await _eliminarSuministro();
            },
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text(
          'Maestro de Suministros',
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
            onPressed: _loadSupplies,
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
                                    items: ["Código", "Nombre", "Categoría"],
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
                                    child: _buildBuscarSuministro(context),
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
                    // Tabla de suministros
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
                                              rows: rowsLista(_supplies),
                                              mode: PlutoGridMode.normal,
                                              onLoaded: (PlutoGridOnLoadedEvent event) {
                                                stateManager = event.stateManager;
                                                stateManager?.setKeepFocus(false);
                                                stateManager?.setShowColumnFilter(true);
                                                stateManager?.setShowColumnFooter(false);
                                              },
                                              onChanged: (event) {},
                                              onRowDoubleTap: (event) {
                                                _editarSuministroSeleccionado(event.row);
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
          await _buscarSuministros();
        },
        icon: const Icon(Icons.search_rounded, color: Colors.white70),
      ),
    );
  }

  Future<void> _loadSupplies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supplies = await MasterSupplyService.getAllSupplies();
      setState(() {
        _supplies.clear();
        _supplies.addAll(supplies);
        _isLoading = false;
      });
      
      if (stateManager?.rows.isNotEmpty == true) {
        stateManager?.removeRows(stateManager!.rows);
      }
      stateManager?.appendRows(rowsLista(_supplies));
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
          desc: 'Error al cargar suministros: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  Future<void> _buscarSuministros() async {
    final query = _buscarSuministroController.text.trim();
    if (query.isEmpty) {
      //await _loadSupplies();
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
    } else if (_verticalGroupValue == "Categoría") {
      filterField = "category";
    }

    try {
      final supplies = await MasterSupplyService.searchSupplies(query, filterField);
      setState(() {
        _supplies.clear();
        _supplies.addAll(supplies);
        _isLoading = false;
      });
      
      if (stateManager?.rows.isNotEmpty == true) {
        stateManager?.removeRows(stateManager!.rows);
      }
      stateManager?.appendRows(rowsLista(_supplies));
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

  TextFormField _buildBuscarSuministro(BuildContext context) {
    return TextFormField(
      controller: _buscarSuministroController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 100,
      decoration: const InputDecoration(
        labelText: 'Buscar suministro...',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  List<PlutoRow> rowsLista(List<MasterSupply> supplies) {
    List<PlutoRow> retorno = [];
    try {
      for (var supply in supplies) {
        retorno.add(
          PlutoRow(
            cells: {
              'Seleccion': PlutoCell(value: false),
              'Código': PlutoCell(value: supply.code),
              'Nombre': PlutoCell(value: supply.name),
              'Descripción': PlutoCell(value: supply.description),
              'Categoría': PlutoCell(value: supply.category),
              'Unidad': PlutoCell(value: supply.unitMeasure),
              'Presentación': PlutoCell(value: supply.presentation),
              'Costo Unitario': PlutoCell(value: supply.unitCost),
              'Precio Venta': PlutoCell(value: supply.salePrice),
              'Stock Mín': PlutoCell(value: supply.minStock),
              'Stock Máx': PlutoCell(value: supply.maxStock),
              'Proveedor': PlutoCell(value: supply.mainSupplier),
              'Ubicación': PlutoCell(value: supply.warehouseLocation),
              'Estado': PlutoCell(value: supply.status ? 'Activo' : 'Inactivo'),
              'ID': PlutoCell(value: supply.supplyId),
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
        width: 100,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
        renderer: (rendererContext) {
          final code = rendererContext.cell.value;
          return Tooltip(
            message: 'Editar Suministro',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  final int supplyId = rendererContext.row.cells['ID']?.value;
                  Navigator.pushNamed(context, '/suministro', arguments: supplyId);
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
        width: 180,
        textAlign: PlutoColumnTextAlign.left,
        type: PlutoColumnType.text(),
      ),
    );

    // Descripción
    list.add(
      PlutoColumn(
        title: 'Descripción',
        field: 'Descripción',
        backgroundColor: colorHeader,
        width: 200,
        textAlign: PlutoColumnTextAlign.left,
        type: PlutoColumnType.text(),
      ),
    );

    // Categoría
    list.add(
      PlutoColumn(
        title: 'Categoría',
        field: 'Categoría',
        backgroundColor: colorHeader,
        width: 120,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
      ),
    );

    // Unidad de Medida
    list.add(
      PlutoColumn(
        title: 'Unidad',
        field: 'Unidad',
        backgroundColor: colorHeader,
        width: 80,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
      ),
    );

    // Presentación
    list.add(
      PlutoColumn(
        title: 'Presentación',
        field: 'Presentación',
        backgroundColor: colorHeader,
        width: 120,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
      ),
    );

    // Costo Unitario
    list.add(
      PlutoColumn(
        title: 'Costo Unitario',
        field: 'Costo Unitario',
        backgroundColor: colorHeader,
        width: 120,
        textAlign: PlutoColumnTextAlign.right,
        type: PlutoColumnType.number(),
      ),
    );

    // Precio de Venta
    list.add(
      PlutoColumn(
        title: 'Precio Venta',
        field: 'Precio Venta',
        backgroundColor: colorHeader,
        width: 120,
        textAlign: PlutoColumnTextAlign.right,
        type: PlutoColumnType.number(),
      ),
    );

    // Stock Mínimo
    list.add(
      PlutoColumn(
        title: 'Stock Mín',
        field: 'Stock Mín',
        backgroundColor: colorHeader,
        width: 80,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.number(),
      ),
    );

    // Stock Máximo
    list.add(
      PlutoColumn(
        title: 'Stock Máx',
        field: 'Stock Máx',
        backgroundColor: colorHeader,
        width: 80,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.number(),
      ),
    );

    // Proveedor Principal
    list.add(
      PlutoColumn(
        title: 'Proveedor',
        field: 'Proveedor',
        backgroundColor: colorHeader,
        width: 150,
        textAlign: PlutoColumnTextAlign.left,
        type: PlutoColumnType.text(),
      ),
    );

    // Ubicación en Almacén
    list.add(
      PlutoColumn(
        title: 'Ubicación',
        field: 'Ubicación',
        backgroundColor: colorHeader,
        width: 120,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
      ),
    );

    // Estado
    list.add(
      PlutoColumn(
        title: 'Estado',
        field: 'Estado',
        backgroundColor: colorHeader,
        width: 80,
        textAlign: PlutoColumnTextAlign.center,
        type: PlutoColumnType.text(),
        renderer: (rendererContext) {
          final estado = rendererContext.cell.value;
          final isActive = estado == 'Activo';
          
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isActive ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              estado,
              style: TextStyle(
                color: isActive ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        },
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

  Future<void> _editarSuministro() async {
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
        desc: 'Por favor seleccione un suministro para editar',
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
        desc: 'Por favor seleccione solo un suministro para editar',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    final selectedRow = selectedRows.first;
    final supplyId = selectedRow.cells['ID']?.value as int?;
    
    if (supplyId != null) {
      Navigator.pushNamed(context, '/suministro', arguments: supplyId);
    }
  }

  void _editarSuministroSeleccionado(PlutoRow row) {
    final supplyId = row.cells['ID']?.value as int?;
    if (supplyId != null) {
      Navigator.pushNamed(context, '/suministro', arguments: supplyId);
    }
  }

  Future<void> _eliminarSuministro() async {
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
        desc: 'Por favor seleccione un suministro para eliminar',
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
        desc: 'Por favor seleccione solo un suministro para eliminar',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    final selectedRow = selectedRows.first;
    final supplyId = selectedRow.cells['ID']?.value as int?;
    final supplyName = selectedRow.cells['Nombre']?.value as String?;
    
    if (supplyId == null) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.error,
        title: 'Error',
        desc: 'No se pudo obtener el ID del suministro',
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
      desc: '¿Está seguro que desea eliminar el suministro:\n\n$supplyName?\n\nEsta acción no se puede deshacer.',
      btnOkText: 'ELIMINAR',
      btnOkColor: Colors.red,
      btnOkOnPress: () async {
        await _ejecutarEliminacion(supplyId, supplyName ?? '');
      },
      btnCancelText: 'CANCELAR',
      btnCancelOnPress: () {},
    ).show();
  }

  Future<void> _ejecutarEliminacion(int supplyId, String supplyName) async {
    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: 'Eliminando suministro...');

    try {
      final success = await MasterSupplyService.deleteSupply(supplyId);
      pr.close();

      if (success) {
        if (mounted) {
          AwesomeDialog(
            context: context,
            animType: AnimType.bottomSlide,
            dialogType: DialogType.success,
            title: 'Eliminación Exitosa',
            desc: 'El suministro $supplyName ha sido eliminado correctamente.',
            btnOkText: 'Aceptar',
            btnOkOnPress: () {
              _loadSupplies();
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
          desc: 'Error al eliminar el suministro: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }
}