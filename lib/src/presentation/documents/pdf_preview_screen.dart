import '../widgets/logo_loader.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Future<Uint8List> Function() buildPdf;
  final String title;

  const PdfPreviewScreen({
    super.key,
    required this.buildPdf,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: PdfPreview(
        build: (format) => buildPdf(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        loadingWidget: const LogoLoader(),
      ),
    );
  }
}
