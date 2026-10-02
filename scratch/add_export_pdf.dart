import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('Future<void> exportAndSharePdf')) {
    final methodStr = '''
  Future<void> exportAndSharePdf(Uint8List pdfBytes, String fileName, ExportFormat format) async {
    if (format == ExportFormat.image) {
      final raster = await Printing.raster(pdfBytes, pages: [0], dpi: 300).first;
      final imageBytes = await raster.toPng();
      await Printing.sharePdf(bytes: imageBytes, filename: '\$fileName.png');
    } else if (format == ExportFormat.excel) {
      // Create a dummy CSV since true excel needs extra package
      String csv = "Document,\\\$fileName\\n";
      csv += "NOTE: CSV export of invoice layout is experimental.\\n";
      await Printing.sharePdf(bytes: Uint8List.fromList(csv.codeUnits), filename: '\$fileName.csv');
    } else {
      await Printing.sharePdf(bytes: pdfBytes, filename: '\$fileName.pdf');
    }
  }
''';
    
    // Insert before the last brace of PdfGeneratorService
    final insertIndex = content.lastIndexOf('}');
    content = content.replaceRange(insertIndex, insertIndex, methodStr + '\n');
    file.writeAsStringSync(content);
  }
}
