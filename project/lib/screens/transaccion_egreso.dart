/* Autor: Pio enrique Olvera Briones
   Fecha: 07/08/2025
   Descripción: pantalla para crear/editar transacciones de egreso de insumos
*/

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:button_navigation_bar/button_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:odontologo/services/outgoing_transaction_service.dart';
import 'package:odontologo/services/master_supply_service.dart';
import 'package:odontologo/object/outgoing_transaction.dart';
import 'package:odontologo/object/master_supply.dart';
import 'package:odontologo/widgets/connection_status.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

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
  String _selectedTransactionType = 'CONSUMPTION';
  String _selectedStatus = 'PENDING';
  final List<String> _transactionTypes = ['CONSUMPTION', 'SALE', 'LOSS', 'ADJUSTMENT'];
  final List<String> _statusOptions = ['PENDING', 'APPROVED', 'REJECTED'];

  // Paciente/Dentista IDs (inputs simples por ahora)
  final _patientIdController = TextEditingController();
  final _dentistIdController = TextEditingController();

  // Detalles
  final List<OutgoingDetailForm> _details = [];

  int? _transactionId;
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
      final supplies = await MasterSupplyService.getAllSupplies();
      setState(() {
        _supplies = supplies;
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

  void _loadTransactionData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is int && args > 0) {
      _transactionId = args;
      _isEditing = true;
      _loadTransaction();
    } else {
      _transactionNumberController.text = OutgoingTransactionService.generateTransactionNumber();
      _transactionDateController.text = DateTime.now().toIso8601String().split('T')[0];
      _addDetail();
    }
  }

  Future<void> _loadTransaction() async {
    if (_transactionId == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final tx = await OutgoingTransactionService.getOutgoingTransactionById(_transactionId!);
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
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
        if (mounted) {
          AwesomeDialog(
            context: context,
            animType: AnimType.bottomSlide,
            dialogType: DialogType.error,
            title: 'Error',
            desc: 'No se encontró la transacción',
            btnOkText: 'Cerrar',
            btnOkOnPress: () { Navigator.pop(context); },
          ).show();
        }
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'Error al cargar la transacción: $e',
          btnOkText: 'Cerrar',
          btnOkOnPress: () { Navigator.pop(context); },
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
            onPressed: () async { await _guardarTransaccion(); },
          ),
          ButtonNavigationItem(
            label: " Limpiar",
            height: 40,
            width: 130,
            icon: const Icon(Icons.clear, color: Colors.white),
            color: Colors.orange[200],
            onPressed: () { _limpiarFormulario(); },
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Transacción de Egreso' : 'Nueva Transacción de Egreso',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: ButtonBack(),
        actions: [ AppBarConnectionStatus() ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _isLoading || _isLoadingDropdowns
        ? const Center(child: CircularProgressIndicator())
        : Form(
          key: _formKey,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [ _buildHeaderSection(), _buildDetailsSection() ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), color: Colors.white,
        boxShadow: const [ BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0,5)) ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Información de Cabecera', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800])),
          ),
          SingleChildScrollView(
            child: Column(children: [
              ResponsiveGridRow(children: [
                ResponsiveGridCol(lg:6,xl:6,md:6,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildTransactionNumberField())),
                ResponsiveGridCol(lg:6,xl:6,md:6,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildTransactionDateField())),
              ]),
              ResponsiveGridRow(children: [
                ResponsiveGridCol(lg:6,xl:6,md:6,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildTransactionTypeDropdown())),
                ResponsiveGridCol(lg:6,xl:6,md:6,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildStatusDropdown())),
              ]),
              ResponsiveGridRow(children: [
                ResponsiveGridCol(lg:6,xl:6,md:6,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildPatientIdField())),
                ResponsiveGridCol(lg:6,xl:6,md:6,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildDentistIdField())),
              ]),
              ResponsiveGridRow(children: [
                ResponsiveGridCol(lg:12,xl:12,md:12,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildReasonField())),
              ]),
              ResponsiveGridRow(children: [
                ResponsiveGridCol(lg:12,xl:12,md:12,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildTotalField())),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), color: Colors.white,
        boxShadow: const [ BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0,5)) ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detalles de la Transacción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                ElevatedButton.icon(onPressed: _addDetail, icon: const Icon(Icons.add), label: const Text('Agregar Detalle'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white)),
              ],
            ),
          ),
          if (_details.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No hay detalles agregados. Haga clic en "Agregar Detalle" para comenzar.', style: TextStyle(fontSize: 16, color: Colors.grey))),
            )
          else
            ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _details.length,
              itemBuilder: (context, index) => _buildDetailCard(index),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Detalle ${index+1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => _removeDetail(index), icon: const Icon(Icons.delete, color: Colors.red), tooltip: 'Eliminar detalle'),
          ]),
          const SizedBox(height: 16),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(lg:6,xl:6,md:6,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildSupplyDropdown(detail))),
            ResponsiveGridCol(lg:6,xl:6,md:6,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildQuantityField(detail))),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(lg:6,xl:6,md:6,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildUnitCostField(detail))),
            ResponsiveGridCol(lg:6,xl:6,md:6,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildSubtotalDetailField(detail))),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(lg:6,xl:6,md:6,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildBatchNumberField(detail))),
            ResponsiveGridCol(lg:6,xl:6,md:6,sm:12,xs:12, child: Container(padding: const EdgeInsets.all(3.0), child: _buildDetailNotesField(detail))),
          ]),
        ]),
      ),
    );
  }

  // Campos cabecera
  TextFormField _buildTransactionNumberField() => TextFormField(controller: _transactionNumberController, readOnly: _isEditing, decoration: const InputDecoration(labelText: 'Número de Transacción *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))) , validator: (v){ if(v==null||v.trim().isEmpty) return 'Ingrese el número de transacción'; return null;});
  TextFormField _buildTransactionDateField() => TextFormField(controller: _transactionDateController, decoration: const InputDecoration(labelText: 'Fecha de Transacción *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))) , validator: (v){ if(v==null||v.trim().isEmpty) return 'Ingrese la fecha de transacción'; return null;});
  DropdownButtonFormField<String> _buildTransactionTypeDropdown() => DropdownButtonFormField<String>(value: _selectedTransactionType, decoration: const InputDecoration(labelText: 'Tipo de Transacción *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))), items: _transactionTypes.map((e)=>DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v){ setState(()=>_selectedTransactionType=v!); });
  DropdownButtonFormField<String> _buildStatusDropdown() => DropdownButtonFormField<String>(value: _selectedStatus, decoration: const InputDecoration(labelText: 'Estado *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))), items: _statusOptions.map((e)=>DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v){ setState(()=>_selectedStatus=v!); });
  TextFormField _buildPatientIdField() => TextFormField(controller: _patientIdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Paciente ID *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))), validator: (v){ if(v==null||v.trim().isEmpty) return 'Ingrese Paciente ID'; if(int.tryParse(v)==null) return 'Ingrese un número válido'; return null;});
  TextFormField _buildDentistIdField() => TextFormField(controller: _dentistIdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Dentista ID *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))), validator: (v){ if(v==null||v.trim().isEmpty) return 'Ingrese Dentista ID'; if(int.tryParse(v)==null) return 'Ingrese un número válido'; return null;});
  TextFormField _buildReasonField() => TextFormField(controller: _reasonController, maxLines: 2, decoration: const InputDecoration(labelText: 'Motivo *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))), validator: (v){ if(v==null||v.trim().isEmpty) return 'Ingrese el motivo'; return null;});
  TextFormField _buildTotalField() => TextFormField(controller: _totalController, readOnly: true, decoration: const InputDecoration(labelText: 'Total', prefixText: '\$ ', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))));

  // Campos detalle
  DropdownButtonFormField<MasterSupply> _buildSupplyDropdown(OutgoingDetailForm d) => DropdownButtonFormField<MasterSupply>(
    value: _supplies.firstWhere((s)=> s.supplyId == d.supplyId, orElse: ()=> MasterSupply(supplyId: 0, code: '', name: '', description: '', category: '', unitMeasure: '', presentation: '', unitCost: 0.00, salePrice: 0.00, minStock: 0, maxStock: 0, mainSupplier: '', warehouseLocation: '', status: true)),
    decoration: const InputDecoration(labelText: 'Suministro *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))),
    items: _supplies.map((s)=> DropdownMenuItem(value: s, child: Text('${s.name} (${s.code})'))).toList(),
    onChanged: (s){ if(s!=null){ setState((){ d.supplyId = s.supplyId!; d.unitCost = s.unitCost; d.calculateSubtotal(); }); _calculateTotals(); } },
  );
  TextFormField _buildQuantityField(OutgoingDetailForm d) => TextFormField(controller: d.quantityController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cantidad *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))), validator: (v){ if(v==null||v.trim().isEmpty) return 'Ingrese la cantidad'; if(double.tryParse(v)==null) return 'Número inválido'; if(double.parse(v)<=0) return 'Debe ser > 0'; return null;}, onChanged: (_){ d.calculateSubtotal(); _calculateTotals(); });
  TextFormField _buildUnitCostField(OutgoingDetailForm d) => TextFormField(controller: d.unitCostController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Costo Unitario *', prefixText: '\$ ', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))), validator: (v){ if(v==null||v.trim().isEmpty) return 'Ingrese costo'; if(double.tryParse(v)==null) return 'Número inválido'; if(double.parse(v)<0) return 'No negativo'; return null;}, onChanged: (_){ d.calculateSubtotal(); _calculateTotals(); });
  TextFormField _buildSubtotalDetailField(OutgoingDetailForm d) => TextFormField(controller: d.subtotalController, readOnly: true, decoration: const InputDecoration(labelText: 'Subtotal', prefixText: '\$ ', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))));
  TextFormField _buildBatchNumberField(OutgoingDetailForm d) => TextFormField(controller: d.batchNumberController, decoration: const InputDecoration(labelText: 'Número de Lote', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))));
  TextFormField _buildDetailNotesField(OutgoingDetailForm d) => TextFormField(controller: d.notesController, decoration: const InputDecoration(labelText: 'Notas del Detalle', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))));

  void _addDetail(){ setState(()=> _details.add(OutgoingDetailForm())); }
  void _removeDetail(int index){ setState(()=> _details.removeAt(index)); _calculateTotals(); }

  void _calculateTotals(){ double total = 0; for(final d in _details){ total += d.subtotal; } _totalController.text = total.toStringAsFixed(2); }

  void _limpiarFormulario(){
    _transactionNumberController.clear(); _transactionDateController.clear(); _reasonController.clear(); _totalController.clear(); _patientIdController.clear(); _dentistIdController.clear();
    setState((){ _selectedTransactionType = 'CONSUMPTION'; _selectedStatus = 'PENDING'; _details.clear(); });
    _transactionNumberController.text = OutgoingTransactionService.generateTransactionNumber();
    _transactionDateController.text = DateTime.now().toIso8601String().split('T')[0];
    _addDetail();
  }

  Future<void> _guardarTransaccion() async {
    if(!_formKey.currentState!.validate()) return;
    if(_details.isEmpty){ AwesomeDialog(context: context, animType: AnimType.bottomSlide, dialogType: DialogType.warning, title: 'Detalles Requeridos', desc: 'Debe agregar al menos un detalle', btnOkOnPress: (){}).show(); return; }

    ProgressDialog pr = ProgressDialog(context: context); pr.show(max: 600, msg: _isEditing ? 'Actualizando egreso...' : 'Guardando egreso...');
    try{
      final details = _details.map((d)=> CreateOutgoingDetail(supplyId: d.supplyId, quantity: d.quantity, unitCost: d.unitCost, subtotal: d.subtotal, batchNumber: d.batchNumber, notes: d.notes)).toList();
      if(_isEditing){
        final tx = OutgoingTransaction(outgoingId: _transactionId, transactionNumber: _transactionNumberController.text.trim(), transactionDate: _transactionDateController.text.trim(), transactionType: _selectedTransactionType, patientId: int.parse(_patientIdController.text.trim()), dentistId: int.parse(_dentistIdController.text.trim()), reason: _reasonController.text.trim(), total: double.parse(_totalController.text.trim()), status: _selectedStatus, details: details.map((d)=> OutgoingDetail(supplyId: d.supplyId, quantity: d.quantity, unitCost: d.unitCost, subtotal: d.subtotal, batchNumber: d.batchNumber, notes: d.notes)).toList());
        await OutgoingTransactionService.updateOutgoingTransaction(tx);
      } else {
        final tx = CreateOutgoingTransaction(transactionNumber: _transactionNumberController.text.trim(), transactionDate: _transactionDateController.text.trim(), transactionType: _selectedTransactionType, patientId: int.parse(_patientIdController.text.trim()), dentistId: int.parse(_dentistIdController.text.trim()), reason: _reasonController.text.trim(), total: double.parse(_totalController.text.trim()), details: details);
        await OutgoingTransactionService.createOutgoingTransaction(tx);
      }
      pr.close();
      if(mounted){ AwesomeDialog(context: context, animType: AnimType.bottomSlide, dialogType: DialogType.success, title: 'Éxito', desc: _isEditing ? 'Egreso actualizado correctamente' : 'Egreso creado correctamente', btnOkOnPress: (){ Navigator.pop(context); }).show(); }
    } catch(e){
      pr.close(); if(mounted){ AwesomeDialog(context: context, animType: AnimType.bottomSlide, dialogType: DialogType.error, title: 'Error', desc: 'Error al guardar el egreso: $e', btnOkOnPress: (){}).show(); }
    }
  }
}

class OutgoingDetailForm{
  int supplyId = 0; double quantity = 0; double unitCost = 0; double subtotal = 0;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitCostController = TextEditingController();
  final TextEditingController subtotalController = TextEditingController();
  final TextEditingController batchNumberController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  void calculateSubtotal(){ quantity = double.tryParse(quantityController.text) ?? 0; unitCost = double.tryParse(unitCostController.text) ?? 0; subtotal = quantity * unitCost; subtotalController.text = subtotal.toStringAsFixed(2); }
  String get batchNumber => batchNumberController.text.trim();
  String get notes => notesController.text.trim();
}