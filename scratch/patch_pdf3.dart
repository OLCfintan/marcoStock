import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  final startHeader = content.indexOf('pw.Widget _buildHeader');
  final endHeader = content.indexOf('pw.Widget _buildInvoiceTable');
  
  final newHeader = '''
  pw.Widget _buildHeader(InvoiceEntity invoice, ClientEntity? client, String companyName, String companyAddress, String companyPhone, String companyTaxId, String companyIce, String companyRc, String companyRib, String companyEmail, pw.ImageProvider? logoImage, AppLocalizations l10n) {
    String docTypeTitle = l10n.pdfFacture;
    if (invoice.documentType == 'BON') docTypeTitle = l10n.pdfBonDeLivraison;
    else if (invoice.documentType == 'COMMANDE') docTypeTitle = l10n.pdfBonDeCommande;
    else if (invoice.documentType == 'TICKET') docTypeTitle = l10n.ticket;

    final clientName = invoice.clientNameOverride ?? client?.name ?? 'Client Passager';
    final clientIce = invoice.clientIceOverride ?? '';
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _bidiText(companyName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  _bidiText('SARL AU', style: pw.TextStyle(fontSize: 10)),
                ]
              )
            ),
            if (logoImage != null)
              pw.Container(
                width: 100,
                height: 60,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              )
            else
              pw.SizedBox(width: 100),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _bidiText('MD DES PRODUITS CHIMIQUES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  _bidiText('IMPORT EXPORT', style: pw.TextStyle(fontSize: 10)),
                ]
              )
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2, color: PdfColor.fromHex('#C5A059')),
        pw.SizedBox(height: 2),
        pw.Divider(thickness: 1, color: PdfColor.fromHex('#C5A059')),
        pw.SizedBox(height: 20),
        
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _bidiText('Casablanca le : \${invoice.date.day.toString().padLeft(2,'0')}/\${invoice.date.month.toString().padLeft(2,'0')}/\${invoice.date.year}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            _bidiText('\${docTypeTitle.toUpperCase()} N°:\${invoice.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 15),
        
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          children: [
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('Client', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('ICE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('Mode de reglement', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
              ]
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText(clientName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText(clientIce.isNotEmpty ? 'ICE : \$clientIce' : '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('Espece', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
              ]
            ),
          ]
        ),
      ],
    );
  }

''';
  
  content = content.replaceRange(startHeader, endHeader, newHeader);
  file.writeAsStringSync(content);
}
