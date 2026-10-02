import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  final startHeader = content.indexOf('pw.Widget _buildInvoiceTable');
  final endHeader = content.indexOf('pw.Widget _buildTotals');
  
  final newHeader = '''
  pw.Widget _buildInvoiceTable(List<InvoiceLineEntity> lines, Map<String, ProductEntity> productMap, AppLocalizations l10n) {
    return pw.TableHelper.fromTextArray(
      headers: ['Produits', 'Quantités', 'P.U HT', 'MT HT'],
      data: lines.map((line) {
        final product = productMap[line.productId];
        String productName = _localizedProductName(product, l10n.localeName);
        
        return [
          productName,
          line.quantity.toStringAsFixed(2),
          line.unitPrice.toStringAsFixed(2) + ' DH',
          line.lineTotal.toStringAsFixed(2) + ' DH',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromHex('#e2e2e2'),
      ),
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      cellPadding: const pw.EdgeInsets.all(6),
      cellStyle: pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
    );
  }

''';
  
  content = content.replaceRange(startHeader, endHeader, newHeader);
  file.writeAsStringSync(content);
}
