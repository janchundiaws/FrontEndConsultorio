
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:odontologo/screens/button_back.dart';
import 'package:odontologo/widgets/toast_msg.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:responsive_grid/responsive_grid.dart';

class AgendarCitas extends StatefulWidget {
  const AgendarCitas({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AgendarCitasScreen createState() => _AgendarCitasScreen();
}

class _AgendarCitasScreen extends State<AgendarCitas>{

  int id = 0;
  bool isReadOnly = false;

  late final PlutoGridStateManager stateManager;
  final List _lisDocumentDetails = [];
  List<PlutoColumn> columns = [];

  // para validación del formulario
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _limpiarVar();
    super.initState();
    columns = _columnsRender();
  }

  void _limpiarVar() {

    id = 0;
    isReadOnly = false;
    
  }

  bool soloLetras(String texto) {
    return RegExp(r"^[A-ZÑÁÉÍÓÚÜ\s]+$").hasMatch(texto.toUpperCase());
  }

  bool esPantallaGrande(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  @override
  void dispose() {
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  final isSmallScreen = MediaQuery.of(context).size.width < 600;
  return Scaffold(
    appBar: AppBar(title: Text('Agenda Pacientes', 
                              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                  leading: ButtonBack(),
                  ), 
    
    body: Stack(
      children: [ 
        Form(
          key: _formKey,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
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
                    //scrollDirection: Axis.horizontal,
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
                                  height: MediaQuery.of(context).size.height * 0.77, //0.6
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                                  child: PlutoGrid(
                                    columns: columns,
                                    rows: rowsLista(_lisDocumentDetails),
                                    mode: PlutoGridMode.normal,
                                    onLoaded: (PlutoGridOnLoadedEvent event) {
                                      stateManager = event.stateManager;
                                      stateManager.setKeepFocus(false);
                                      event.stateManager.setShowColumnFilter(true,);
                                      event.stateManager.setShowColumnFooter(false,);
                                    },
                                    onChanged: (event) {},
                                    onRowDoubleTap: (event) {},
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
      ]
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () async {
        Navigator.pushNamed(context, '/citas');
        //ToastMSG.showInfo(context, 'Añadir Citas', 2);

      },
      tooltip: 'Añadir Citas',
      child: const Icon(Icons.add_task_rounded),
    ), 
  );
}

// datos personales -- Historia Clinica

List<PlutoRow> rowsLista(List info) {
  List<PlutoRow> retorno = [];
  try {
    for (var rowInfo in info) {
      retorno.add(
        PlutoRow(
          cells: {
            'Cedula': PlutoCell(value: rowInfo['cedula']),
            'Nombres': PlutoCell(value: rowInfo['nombres']),
            'Telefono': PlutoCell(value: rowInfo['telefono']),
            'Correo': PlutoCell(value: rowInfo['correo']),
            'FechaHora': PlutoCell(value: rowInfo['fechahora']),
            'DentistsId': PlutoCell(value: rowInfo['dentistsid']),
            'Dentista': PlutoCell(value: rowInfo['dentista']),
            'Especialidad': PlutoCell(value: rowInfo['especialidad']),
            'OfficeId': PlutoCell(value: rowInfo['officeid']),
            'OfficeName': PlutoCell(value: rowInfo['officename']),
            'Reason': PlutoCell(value: rowInfo['observacion']),
            'id': PlutoCell(value: rowInfo['id']),
          },
        ),
      );
    }
  } on Exception catch (e) {
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
  Color colorHeader = Colors.lightBlue;
  List<PlutoColumn> list = [];

  list.add(
    PlutoColumn(
      title: 'Documento Id',
      field: 'Cedula',
      readOnly: true,
      backgroundColor: colorHeader,
      width: 120, 
      frozen: PlutoColumnFrozen.start,
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
    ),
  );
  list.add(
    PlutoColumn(
      title: 'Nombres',
      field: 'Nombres',
      readOnly: true,
      backgroundColor: colorHeader,
      width: 250, 
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
    ),
  );
  list.add(
    PlutoColumn(
      title: 'Teléfono',
      field: 'Telefono',
      readOnly: true,
      backgroundColor: colorHeader,
      width: 150, 
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
    ),
  );
  list.add(
    PlutoColumn(
      title: 'Correo',
      field: 'Correo',
      readOnly: true,
      backgroundColor: colorHeader,
      width: 150, 
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
    ),
  );    
  list.add(
    PlutoColumn(
      title: 'Fecha/Hora',
      field: 'FechaHora',
      readOnly: true,
      backgroundColor: colorHeader,
      width: 150, 
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
    ),
  );
  list.add(
    PlutoColumn(
      title: 'dentistsId',
      field: 'DentistsId',
      readOnly: true,
      hide: true,
      backgroundColor: colorHeader,
      width: 70, 
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
    ),
  );
  list.add(
    PlutoColumn(
      title: 'Médico',
      field: 'Dentista',
      readOnly: true,
      backgroundColor: colorHeader,
      width: 120, 
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
    ),
  );
  list.add(
    PlutoColumn(
      title: 'Especialidad',
      field: 'Especialidad',
      readOnly: true,
      backgroundColor: colorHeader,
      width: 120, 
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
    ),
  );  
  list.add(
    PlutoColumn(
      title: 'OfficeId',
      field: 'OfficeId',
      readOnly: true,
      hide: true,
      backgroundColor: colorHeader,
      width: 70, 
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
    ),
  );   
  list.add(
    PlutoColumn(
      title: 'Lugar',
      field: 'OfficeName',
      readOnly: true,
      backgroundColor: colorHeader,
      width: 120, 
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
    ),
  ); 
  list.add(
    PlutoColumn(
      title: 'Observación',
      field: 'Reason',
      readOnly: true,
      backgroundColor: colorHeader,
      width: 200, 
      textAlign: PlutoColumnTextAlign.left,
      type: PlutoColumnType.text(),
    ),
  );

  list.add(
    PlutoColumn(
      title: 'Acción',
      field: 'id',
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
      renderer: (rendererContext) {
        return Row(
          children: [
            Expanded(
              child: Tooltip(
                message: 'Editar',
                child: IconButton(
                  icon: const Icon(Icons.edit_calendar, color: Colors.green),
                  onPressed: () {
                    //final int idPatient = rendererContext.row.cells['id2']?.value;
                    //final String documentId = rendererContext.row.cells['Cedula']?.value;
                    //final String name = rendererContext.row.cells['Nombres']?.value;
                    //final String lastName = rendererContext.row.cells['Apellidos']?.value;

                    //Navigator.pushNamed(context,'/historia',arguments: {'idPatient': idPatient,'documentId': documentId,'name':name,'lastName':lastName},); 
                    ToastMSG.showInfo(context, 'Press Editar', 2);
                  },
                  iconSize: 13,
                  padding: const EdgeInsets.all(2),
                ),
              ),
            ),
             Expanded(
              child: Tooltip(
                message: 'Eliminar',
                child: IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.blue),
                  onPressed: () {
                    ToastMSG.showInfo(context, 'Press Elimnar', 2);
                  },
                  iconSize: 13,
                  padding: const EdgeInsets.all(2),
                ),
              ),
            ),               
          ],
        );
      },
    ),
  );

  return list;
}

}

