import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class PdfService {
  static Future<Uint8List> generatePatientPdf(Map<String, dynamic> patientData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'CLÍNICA ODONTOLÓGICA',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'FICHA DEL PACIENTE',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        font: pw.Font.helvetica(),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Patient Information
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INFORMACION PERSONAL',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                        font: pw.Font.helvetica(),
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    
                    // Personal Data Table
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      children: [
                        _buildTableRow('Documento:', patientData['documentId'] ?? ''),
                        _buildTableRow('Nombres:', patientData['name'] ?? ''),
                        _buildTableRow('Apellidos:', patientData['lastName'] ?? ''),
                        _buildTableRow('Fecha de Nacimiento:', _formatDate(patientData['birthDate'] ?? '')),
                        _buildTableRow('Edad:', '${patientData['edad'] ?? ''} años'),
                        _buildTableRow('Dirección:', patientData['address'] ?? ''),
                        _buildTableRow('Teléfonos:', patientData['phone'] ?? ''),
                        _buildTableRow('Email:', patientData['email'] ?? ''),
                        _buildTableRow('Estado Civil:', patientData['maritalStatus'] ?? ''),
                        _buildTableRow('Tipo de Sangre:', patientData['bloodType'] ?? ''),
                      ],
                    ),
                    
                    pw.SizedBox(height: 20),
                    
                    // Observations Section
                    pw.Text(
                      'OBSERVACIONES',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                        font: pw.Font.helvetica(),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Text(
                        patientData['observations'] ?? 'Sin observaciones registradas',
                        style: pw.TextStyle(
                          fontSize: 12,
                          font: pw.Font.helvetica(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Documento generado el ${_formatDateTime(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Clínica Odontológica - Sistema de Gestión',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              font: pw.Font.helvetica(),
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              font: pw.Font.helvetica(),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  static Future<void> savePdf(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(pdfBytes);
  }

  // Generar reporte de stock de suministros
  static Future<Uint8List> generateStockReportPdf(List<dynamic> stockList) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'CLINICA ODONTOLOGICA',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        font: pw.Font.helvetica(),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'REPORTE DE STOCK - SUMINISTROS',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        font: pw.Font.helvetica(),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Generado el ${_formatDateTime(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                        font: pw.Font.helvetica(),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Tabla de stock
              pw.Container(
                width: double.infinity,
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: const {
                    0: pw.FixedColumnWidth(40),   // ID
                    1: pw.FixedColumnWidth(60),   // Código
                    2: pw.FixedColumnWidth(120),  // Nombre
                    3: pw.FixedColumnWidth(60),   // Categoría
                    4: pw.FixedColumnWidth(60),   // Lote
                    5: pw.FixedColumnWidth(50),   // Disponible
                    6: pw.FixedColumnWidth(50),   // Reservado
                    7: pw.FixedColumnWidth(50),   // Total
                    8: pw.FixedColumnWidth(50),   // Costo
                    9: pw.FixedColumnWidth(60),  // Vencimiento
                    10: pw.FixedColumnWidth(80), // Ubicación
                    11: pw.FixedColumnWidth(40), // Mín
                    12: pw.FixedColumnWidth(40), // Máx
                    13: pw.FixedColumnWidth(60), // Estado
                  },
                  children: [
                    // Header de la tabla
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildTableCell('ID', isHeader: true),
                        _buildTableCell('Codigo', isHeader: true),
                        _buildTableCell('Nombre', isHeader: true),
                        _buildTableCell('Cat.', isHeader: true),
                        _buildTableCell('Lote', isHeader: true),
                        _buildTableCell('Disp.', isHeader: true),
                        _buildTableCell('Res.', isHeader: true),
                        _buildTableCell('Total', isHeader: true),
                        _buildTableCell('Costo', isHeader: true),
                        _buildTableCell('Venc.', isHeader: true),
                        _buildTableCell('Ubicacion', isHeader: true),
                        _buildTableCell('Min', isHeader: true),
                        _buildTableCell('Max', isHeader: true),
                        _buildTableCell('Estado', isHeader: true),
                      ],
                    ),
                    // Filas de datos
                                         ...stockList.map((stock) {
                       return pw.TableRow(
                         children: [
                           _buildTableCell('${stock.stockId}'),
                           _buildTableCell(stock.code),
                           _buildTableCell(stock.name),
                           _buildTableCell(stock.category),
                           _buildTableCell(stock.batchNumber),
                           _buildTableCell(stock.availableQuantity),
                           _buildTableCell(stock.reservedQuantity),
                           _buildTableCell(stock.totalQuantity),
                           _buildTableCell('\$${stock.averageCost}'),
                           _buildTableCell(_formatDate(stock.expirationDate)),
                           _buildTableCell(stock.warehouseLocation),
                           _buildTableCell('${stock.minStock}'),
                           _buildTableCell('${stock.maxStock}'),
                           _buildTableCell(stock.stockStatus),
                         ],
                       );
                     }),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Resumen
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total Items', '${stockList.length}'),
                    _buildSummaryItem('Valor Total', '\$${_calculateTotalValue(stockList)}'),
                    _buildSummaryItem('Stock Bajo', '${_countLowStock(stockList)}'),
                    _buildSummaryItem('Items Expirados', '${_countExpiredItems(stockList)}'),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  'Clinica Odontologica - Sistema de Gestion - Pagina 1',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                    font: pw.Font.helvetica(),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          font: pw.Font.helvetica(), // Usar fuente Helvetica que tiene mejor soporte
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            font: pw.Font.helvetica(),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            font: pw.Font.helvetica(),
          ),
        ),
      ],
    );
  }

  static String _calculateTotalValue(List<dynamic> stockList) {
    double total = 0.0;
    for (final stock in stockList) {
      final quantity = double.tryParse(stock.totalQuantity) ?? 0.0;
      final cost = double.tryParse(stock.averageCost) ?? 0.0;
      total += quantity * cost;
    }
    return total.toStringAsFixed(2);
  }

  static int _countLowStock(List<dynamic> stockList) {
    int count = 0;
    for (final stock in stockList) {
      final availableQty = double.tryParse(stock.availableQuantity) ?? 0.0;
      if (availableQty <= stock.minStock) {
        count++;
      }
    }
    return count;
  }

  static int _countExpiredItems(List<dynamic> stockList) {
    int count = 0;
    final now = DateTime.now();
    for (final stock in stockList) {
      if (stock.expirationDate.isNotEmpty) {
        try {
          final expirationDate = DateTime.parse(stock.expirationDate);
          if (expirationDate.isBefore(now)) {
            count++;
          }
        } catch (e) {
          // Ignorar fechas inválidas
        }
      }
    }
    return count;
  }
} 