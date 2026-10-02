import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    'pw.Widget _buildOldTotalRow(String label, String amount, {bool isBold = false, double? fontSize, PdfColor? color}\n}',
    '''pw.Widget _buildOldTotalRow(String label, String amount, {bool isBold = false, double? fontSize, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _bidiText(
            label, 
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: fontSize,
              color: color,
            )
          ),
          _bidiText(
            amount, 
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: fontSize,
              color: color,
            )
          ),
        ],
      ),
    );
  }
}'''
  );
  
  file.writeAsStringSync(content);
}
