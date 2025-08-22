import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:odontologo/screens/button_back.dart';

class PdfViewerScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String patientName;

  const PdfViewerScreen({
    super.key,
    required this.pdfBytes,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ficha de $patientName',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: ButtonBack(),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              Printing.layoutPdf(
                onLayout: (format) async => pdfBytes,
              );
            },
            tooltip: 'Imprimir',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Aquí se puede implementar la funcionalidad de compartir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad de compartir en desarrollo'),
                ),
              );
            },
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfBytes,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        maxPageWidth: 700,
        
      ),
    );
  }
} 