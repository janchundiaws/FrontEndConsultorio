/* Autor: Pio enrique Olvera Briones
   Fecha: 07/08/2025
   Descripción: pantalla para crear/editar maestros de suministros
*/

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:button_navigation_bar/button_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:odontologo/services/master_supply_service.dart';
import 'package:odontologo/object/master_supply.dart';
import 'package:odontologo/object/inventory_models.dart';
import 'package:odontologo/widgets/connection_status.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

class Suministro extends StatefulWidget {
  const Suministro({super.key});

  @override
  State<Suministro> createState() => _SuministroState();
}

class _SuministroState extends State<Suministro> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers para los campos del formulario
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _presentationController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _mainSupplierController = TextEditingController();
  final _warehouseLocationController = TextEditingController();

  // Dropdowns
  List<UnitOfMeasure> _units = [];
  List<SupplyCategory> _categories = [];
  UnitOfMeasure? _selectedUnit;
  SupplyCategory? _selectedCategory;
  bool _status = true;

  int? _supplyId;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isLoadingDropdowns = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _presentationController.dispose();
    _unitCostController.dispose();
    _salePriceController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _mainSupplierController.dispose();
    _warehouseLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadDropdownData();
    _loadSupplyData();
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      _isLoadingDropdowns = true;
    });

    try {
      final units = await MasterSupplyService.getAllUnits();
      final categories = await MasterSupplyService.getAllCategories();
      
      setState(() {
        _units = units;
        _categories = categories;
        _isLoadingDropdowns = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDropdowns = false;
      });
      
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'Error al cargar datos del formulario: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  void _loadSupplyData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is int && args > 0) {
      _supplyId = args;
      _isEditing = true;
      _loadSupply();
    }
  }

  Future<void> _loadSupply() async {
    if (_supplyId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supply = await MasterSupplyService.getSupplyById(_supplyId!);
      
      if (supply != null) {
        setState(() {
          _codeController.text = supply.code;
          _nameController.text = supply.name;
          _descriptionController.text = supply.description;
          _presentationController.text = supply.presentation;
          _unitCostController.text = supply.unitCost.toString();
          _salePriceController.text = supply.salePrice.toString();
          _minStockController.text = supply.minStock.toString();
          _maxStockController.text = supply.maxStock.toString();
          _mainSupplierController.text = supply.mainSupplier;
          _warehouseLocationController.text = supply.warehouseLocation;
          _status = supply.status;
          
          // Buscar y asignar la categoría seleccionada
          try {
            _selectedCategory = _categories.firstWhere(
              (cat) => cat.name == supply.category,
            );
          } catch (e) {
            _selectedCategory = null;
          }
          
          // Buscar y asignar la unidad seleccionada
          try {
            _selectedUnit = _units.firstWhere(
              (unit) => unit.name == supply.unitMeasure,
            );
          } catch (e) {
            _selectedUnit = null;
          }
          
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
            desc: 'No se encontró el suministro',
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
          desc: 'Error al cargar el suministro: $e',
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
              await _guardarSuministro();
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
        ],
      ),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Suministro' : 'Nuevo Suministro',
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
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                              // Información básica
                              ResponsiveGridRow(
                                children: [
                                  ResponsiveGridCol(
                                    lg: 6,
                                    xl: 6,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: _buildCodeField(),
                                    ),
                                  ),
                                  ResponsiveGridCol(
                                    lg: 6,
                                    xl: 6,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: _buildNameField(),
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
                                      child: _buildDescriptionField(),
                                    ),
                                  ),
                                ],
                              ),
                              ResponsiveGridRow(
                                children: [
                                  ResponsiveGridCol(
                                    lg: 6,
                                    xl: 6,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: _buildCategoryDropdown(),
                                    ),
                                  ),
                                  ResponsiveGridCol(
                                    lg: 6,
                                    xl: 6,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: _buildUnitMeasureDropdown(),
                                    ),
                                  ),
                                ],
                              ),
                              ResponsiveGridRow(
                                children: [
                                  ResponsiveGridCol(
                                    lg: 6,
                                    xl: 6,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: _buildPresentationField(),
                                    ),
                                  ),
                                  ResponsiveGridCol(
                                    lg: 6,
                                    xl: 6,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: _buildStatusField(),
                                    ),
                                  ),
                                ],
                              ),
                              ResponsiveGridRow(
                                children: [
                                  ResponsiveGridCol(
                                    lg: 6,
                                    xl: 6,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: _buildUnitCostField(),
                                    ),
                                  ),
                                  ResponsiveGridCol(
                                    lg: 6,
                                    xl: 6,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: _buildSalePriceField(),
                                    ),
                                  ),
                                ],
                              ),
                              ResponsiveGridRow(
                                children: [
                                  ResponsiveGridCol(
                                    lg: 6,
                                    xl: 6,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: _buildMinStockField(),
                                    ),
                                  ),
                                  ResponsiveGridCol(
                                    lg: 6,
                                    xl: 6,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: _buildMaxStockField(),
                                    ),
                                  ),
                                ],
                              ),
                              ResponsiveGridRow(
                                children: [
                                  ResponsiveGridCol(
                                    lg: 6,
                                    xl: 6,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: _buildMainSupplierField(),
                                    ),
                                  ),
                                  ResponsiveGridCol(
                                    lg: 6,
                                    xl: 6,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.0),
                                      child: _buildWarehouseLocationField(),
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
    );
  }

  // ==================== CAMPOS DEL FORMULARIO ====================

  TextFormField _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 20,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el código del suministro';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Código *',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildNameField() {
    return TextFormField(
      controller: _nameController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el nombre del suministro';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Nombre *',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 300,
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese la descripción';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Descripción *',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  DropdownButtonFormField<SupplyCategory> _buildCategoryDropdown() {
    return DropdownButtonFormField<SupplyCategory>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Categoría *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      validator: (value) {
        if (value == null) {
          return 'Seleccione una categoría';
        }
        return null;
      },
      items: _categories.map((category) {
        return DropdownMenuItem<SupplyCategory>(
          value: category,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: (SupplyCategory? newValue) {
        setState(() {
          _selectedCategory = newValue;
        });
      },
    );
  }

  DropdownButtonFormField<UnitOfMeasure> _buildUnitMeasureDropdown() {
    return DropdownButtonFormField<UnitOfMeasure>(
      value: _selectedUnit,
      decoration: const InputDecoration(
        labelText: 'Unidad de Medida *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      validator: (value) {
        if (value == null) {
          return 'Seleccione una unidad de medida';
        }
        return null;
      },
      items: _units.map((unit) {
        return DropdownMenuItem<UnitOfMeasure>(
          value: unit,
          child: Text(unit.name),
        );
      }).toList(),
      onChanged: (UnitOfMeasure? newValue) {
        setState(() {
          _selectedUnit = newValue;
        });
      },
    );
  }

  TextFormField _buildPresentationField() {
    return TextFormField(
      controller: _presentationController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese la presentación';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Presentación *',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  SwitchListTile _buildStatusField() {
    return SwitchListTile(
      title: const Text('Estado'),
      subtitle: Text(_status ? 'Activo' : 'Inactivo'),
      value: _status,
      onChanged: (bool value) {
        setState(() {
          _status = value;
        });
      },
      activeColor: Colors.green,
    );
  }

  TextFormField _buildUnitCostField() {
    return TextFormField(
      controller: _unitCostController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el costo unitario';
        }
        if (double.tryParse(value) == null) {
          return 'Ingrese un número válido';
        }
        if (double.parse(value) < 0) {
          return 'El costo no puede ser negativo';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Costo Unitario *',
        prefixText: '\$ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildSalePriceField() {
    return TextFormField(
      controller: _salePriceController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el precio de venta';
        }
        if (double.tryParse(value) == null) {
          return 'Ingrese un número válido';
        }
        if (double.parse(value) < 0) {
          return 'El precio no puede ser negativo';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Precio de Venta *',
        prefixText: '\$ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildMinStockField() {
    return TextFormField(
      controller: _minStockController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el stock mínimo';
        }
        if (int.tryParse(value) == null) {
          return 'Ingrese un número entero válido';
        }
        if (int.parse(value) < 0) {
          return 'El stock no puede ser negativo';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Stock Mínimo *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildMaxStockField() {
    return TextFormField(
      controller: _maxStockController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el stock máximo';
        }
        if (int.tryParse(value) == null) {
          return 'Ingrese un número entero válido';
        }
        if (int.parse(value) < 0) {
          return 'El stock no puede ser negativo';
        }
        // Validar que el stock máximo sea mayor al mínimo
        if (_minStockController.text.isNotEmpty) {
          final minStock = int.tryParse(_minStockController.text);
          if (minStock != null && int.parse(value) <= minStock) {
            return 'El stock máximo debe ser mayor al mínimo';
          }
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Stock Máximo *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildMainSupplierField() {
    return TextFormField(
      controller: _mainSupplierController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 200,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el proveedor principal';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Proveedor Principal *',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildWarehouseLocationField() {
    return TextFormField(
      controller: _warehouseLocationController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese la ubicación en almacén';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Ubicación en Almacén *',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  // ==================== ACCIONES ====================

  void _limpiarFormulario() {
    _codeController.clear();
    _nameController.clear();
    _descriptionController.clear();
    _presentationController.clear();
    _unitCostController.clear();
    _salePriceController.clear();
    _minStockController.clear();
    _maxStockController.clear();
    _mainSupplierController.clear();
    _warehouseLocationController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedUnit = null;
      _status = true;
    });
  }

  Future<void> _guardarSuministro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null || _selectedUnit == null) {
      AwesomeDialog(
        context: context,
        animType: AnimType.bottomSlide,
        dialogType: DialogType.warning,
        title: 'Campos Requeridos',
        desc: 'Por favor seleccione una categoría y unidad de medida',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: _isEditing ? 'Actualizando suministro...' : 'Guardando suministro...');

    try {
      if (_isEditing) {
        // Actualizar suministro existente
        final supply = MasterSupply(
          supplyId: _supplyId,
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory!.name,
          unitMeasure: _selectedUnit!.name,
          presentation: _presentationController.text.trim(),
          unitCost: double.tryParse(_unitCostController.text.trim()) ?? 0.0,
          salePrice: double.tryParse(_salePriceController.text.trim()) ?? 0.0,
          minStock: int.parse(_minStockController.text.trim()),
          maxStock: int.parse(_maxStockController.text.trim()),
          mainSupplier: _mainSupplierController.text.trim(),
          warehouseLocation: _warehouseLocationController.text.trim(),
          status: _status,
        );

        await MasterSupplyService.updateSupply(supply);
      } else {
        // Crear nuevo suministro
        final supply = CreateMasterSupply(
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory!.name,
          unitMeasure: _selectedUnit!.name,
          presentation: _presentationController.text.trim(),
          unitCost: double.tryParse(_unitCostController.text.trim()) ?? 0.0,
          salePrice: double.tryParse(_salePriceController.text.trim()) ?? 0.0,
          minStock: int.parse(_minStockController.text.trim()),
          maxStock: int.parse(_maxStockController.text.trim()),
          mainSupplier: _mainSupplierController.text.trim(),
          warehouseLocation: _warehouseLocationController.text.trim(),
          status: _status,
        );

        await MasterSupplyService.createSupply(supply);
      }

      pr.close();

      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.success,
          title: 'Éxito',
          desc: _isEditing 
              ? 'Suministro actualizado correctamente'
              : 'Suministro creado correctamente',
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
          desc: 'Error al guardar el suministro: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }
}