/* Autor: Pio enrique Olvera Briones
   Fecha: 07/08/2025
   Descripción: pantalla para crear/editar proveedores
*/

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:button_navigation_bar/button_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:odontologo/services/supplier_service.dart';
import 'package:odontologo/object/supplier.dart';
import 'package:odontologo/widgets/connection_status.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

class Proveedor extends StatefulWidget {
  const Proveedor({super.key});

  @override
  State<Proveedor> createState() => _ProveedorState();
}

class _ProveedorState extends State<Proveedor> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers para los campos del formulario
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _mainContactController = TextEditingController();

  int? _supplierId;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSupplierData();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _businessNameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _mainContactController.dispose();
    super.dispose();
  }

  void _loadSupplierData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is int && args > 0) {
      _supplierId = args;
      _isEditing = true;
      _loadSupplier();
    }
  }

  Future<void> _loadSupplier() async {
    if (_supplierId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supplier = await SupplierService.getSupplierById(_supplierId!);
      
      if (supplier != null) {
        setState(() {
          _codeController.text = supplier.code;
          _nameController.text = supplier.name;
          _businessNameController.text = supplier.businessName;
          _taxIdController.text = supplier.taxId;
          _addressController.text = supplier.address;
          _phoneController.text = supplier.phone;
          _emailController.text = supplier.email;
          _mainContactController.text = supplier.mainContact;
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
            desc: 'No se encontró el proveedor',
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
          desc: 'Error al cargar el proveedor: $e',
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
              await _guardarProveedor();
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
          _isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor',
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
      body: _isLoading
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
                                      child: _buildBusinessNameField(),
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
                                      child: _buildTaxIdField(),
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
                                      child: _buildPhoneField(),
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
                                      child: _buildAddressField(),
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
                                      child: _buildEmailField(),
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
                                      child: _buildMainContactField(),
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

  TextFormField _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 20,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el código del proveedor';
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
          return 'Ingrese el nombre del proveedor';
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

  TextFormField _buildBusinessNameField() {
    return TextFormField(
      controller: _businessNameController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 200,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese la razón social';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Razón Social *',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildTaxIdField() {
    return TextFormField(
      controller: _taxIdController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 20,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el RUC';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'RUC *',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.phone,
      maxLength: 20,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el teléfono';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Teléfono *',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 300,
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese la dirección';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Dirección *',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.emailAddress,
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Ingrese un email válido';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Email *',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextFormField _buildMainContactField() {
    return TextFormField(
      controller: _mainContactController,
      autocorrect: false,
      textAlign: TextAlign.start,
      keyboardType: TextInputType.text,
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingrese el contacto principal';
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Contacto Principal *',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  void _limpiarFormulario() {
    _codeController.clear();
    _nameController.clear();
    _businessNameController.clear();
    _taxIdController.clear();
    _addressController.clear();
    _phoneController.clear();
    _emailController.clear();
    _mainContactController.clear();
  }

  Future<void> _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ProgressDialog pr = ProgressDialog(context: context);
    pr.show(max: 600, msg: _isEditing ? 'Actualizando proveedor...' : 'Guardando proveedor...');

    try {
      if (_isEditing) {
        // Actualizar proveedor existente
        final supplier = Supplier(
          supplierId: _supplierId,
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          businessName: _businessNameController.text.trim(),
          taxId: _taxIdController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          mainContact: _mainContactController.text.trim(),
        );

        await SupplierService.updateSupplier(supplier);
      } else {
        // Crear nuevo proveedor
        final supplier = CreateSupplier(
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          businessName: _businessNameController.text.trim(),
          taxId: _taxIdController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          mainContact: _mainContactController.text.trim(),
        );

        await SupplierService.createSupplier(supplier);
      }

      pr.close();

      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.success,
          title: 'Éxito',
          desc: _isEditing 
              ? 'Proveedor actualizado correctamente'
              : 'Proveedor creado correctamente',
          btnOkText: 'Aceptar',
          btnOkOnPress: () {
            Navigator.pop(context);
          },
        ).show();
      }
    } catch (e) {
      pr.close();
      //print('Error al guardar el proveedor: $e');
   
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'Error al guardar el proveedor: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

} 