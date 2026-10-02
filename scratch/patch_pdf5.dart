import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  final startHeader = content.indexOf('pw.Widget _buildTotals');
  final endHeader = content.indexOf('pw.Widget _buildTotalRow');
  
  final newHeader = '''
  pw.Widget _buildTotals(InvoiceEntity invoice, AppLocalizations l10n, String companyAddress, String companyIce, String companyRc, String companyRib, String companyEmail, String companyPhone) {
    final amountWords = decimalToWordsFrench(invoice.total.toDouble(), 'dirhams', 'centimes');
    
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Container(
              width: 300,
              child: pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('Total HT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('MT TVA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('TOTAL TTC', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    ]
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('\${invoice.subtotal.toStringAsFixed(2)} DH', style: pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('\${invoice.taxes.toStringAsFixed(2)} DH', style: pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('\${invoice.total.toStringAsFixed(2)} DH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    ]
                  ),
                ]
              ),
            ),
          ]
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          alignment: pw.Alignment.centerLeft,
          child: _bidiText('Arrêté la présente facture à la somme de : \${amountWords.substring(0,1).toUpperCase() + amountWords.substring(1)}.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 40),
        
        // Footer Signature Area
        pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(right: 50),
          child: pw.Container(
            width: 150,
            height: 80,
            // You can add a signature image here if needed, or leave it blank
          ),
        ),
        
        pw.Spacer(),
        pw.Divider(thickness: 2, color: PdfColor.fromHex('#C5A059')),
        pw.SizedBox(height: 2),
        pw.Divider(thickness: 1, color: PdfColor.fromHex('#C5A059')),
        pw.SizedBox(height: 4),
        
        // Footer Details
        pw.Container(
          alignment: pw.Alignment.center,
          child: _bidiText('SIEGE SOCIAL : \$companyAddress', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#C5A059'), fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          alignment: pw.Alignment.center,
          child: _bidiText('RIB : \$companyRib | ICE : \$companyIce | RC : \$companyRc', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _bidiText(companyEmail, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 10),
            _bidiText(companyPhone, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ]
        ),
      ]
    );
  }

''';
  
  content = content.replaceRange(startHeader, endHeader, newHeader);
  
  // Need to update the call to _buildTotals in generateInvoicePdf
  final callTotals = "_buildTotals(invoice, l10n, companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone),";
  content = content.replaceAll("_buildTotals(invoice, l10n),", callTotals);
  
  file.writeAsStringSync(content);
}
