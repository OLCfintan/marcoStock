import 'dart:io';

void main() {
  final oldFile = File('scratch/old_pdf_generator.dart');
  final currentFile = File('lib/src/application/documents/pdf_generator.dart');
  
  String oldContent = oldFile.readAsStringSync();
  String currentContent = currentFile.readAsStringSync();
  
  // Extract OLD methods.
  String extractMethod(String name) {
    int start = oldContent.indexOf('pw.Widget $name(');
    if (start == -1) return '';
    int openBraces = 0;
    int end = -1;
    for (int i = start; i < oldContent.length; i++) {
      if (oldContent[i] == '{') openBraces++;
      if (oldContent[i] == '}') {
        openBraces--;
        if (openBraces == 0) {
          end = i + 1;
          break;
        }
      }
    }
    return oldContent.substring(start, end);
  }
  
  String oldHeader = extractMethod('_buildHeader').replaceAll('_buildHeader', '_buildOldHeader');
  String oldTable = extractMethod('_buildInvoiceTable').replaceAll('_buildInvoiceTable', '_buildOldInvoiceTable');
  String oldTotals = extractMethod('_buildTotals').replaceAll('_buildTotals', '_buildOldTotals');
  String oldTotalRow = extractMethod('_buildTotalRow').replaceAll('_buildTotalRow', '_buildOldTotalRow');
  oldTotals = oldTotals.replaceAll('_buildTotalRow', '_buildOldTotalRow');
  
  // Current methods renamed
  currentContent = currentContent.replaceAll('pw.Widget _buildHeader(', 'pw.Widget _buildFactureHeader(');
  currentContent = currentContent.replaceAll('pw.Widget _buildInvoiceTable(', 'pw.Widget _buildFactureInvoiceTable(');
  currentContent = currentContent.replaceAll('pw.Widget _buildTotals(', 'pw.Widget _buildFactureTotals(');
  
  // Inject old helpers at bottom
  int lastBrace = currentContent.lastIndexOf('}');
  currentContent = currentContent.substring(0, lastBrace) + 
      '\n\n' + oldHeader + '\n\n' + oldTable + '\n\n' + oldTotals + '\n\n' + oldTotalRow + '\n}\n';
      
  // Fix _buildFactureTotals Math block
  String currentTotalsMethod = '''
  pw.Widget _buildFactureTotals(InvoiceEntity invoice, AppLocalizations l10n, String companyAddress, String companyIce, String companyRc, String companyRib, String companyEmail, String companyPhone) {
    final amountWords = decimalToWordsTranslated(invoice.total.toDouble(), l10n.localeName);
    
    // Facture Math logic
    final totalTtc = invoice.total.toDouble();
    final mtHt = totalTtc / 1.20;
    final mtTva = mtHt * 0.20;
    
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
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('\${mtHt.toStringAsFixed(2)} DH', style: pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('\${mtTva.toStringAsFixed(2)} DH', style: pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('\${totalTtc.toStringAsFixed(2)} DH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    ]
                  ),
                ]
              ),
            ),
          ]
        ),
''';

  int startFT = currentContent.indexOf('pw.Widget _buildFactureTotals');
  int endFTRow = currentContent.indexOf('pw.SizedBox(height: 15),', startFT);
  currentContent = currentContent.replaceRange(startFT, endFTRow, currentTotalsMethod);
  
  // Swap _addPages call in generateInvoicePdf
  String oldAddPagesCall = '''
    final isFactureDoc = invoice.documentType == 'FACTURE' || invoice.documentType == 'FACTURE_DUMMY';
    _addPages(doc, options, textDir, watermarkBg, isFactureDoc, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone) : null, () {
      if (isFactureDoc) {
        return [
          _buildFactureHeader(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, companyIce, companyRc, companyRib, companyEmail, logoImage ?? watermarkBg, l10n),
          pw.SizedBox(height: 15),
          _buildFactureInvoiceTable(lines, productMap, l10n),
          pw.SizedBox(height: 15),
          _buildFactureTotals(invoice, l10n, companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone),
        ];
      } else {
        return [
          _buildOldHeader(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, logoImage, l10n),
          pw.SizedBox(height: 32),
          _buildOldInvoiceTable(lines, productMap, l10n),
          pw.SizedBox(height: 16),
          _buildOldTotals(invoice, l10n),
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Container(
            alignment: pw.Alignment.center,
            child: _bidiText(l10n.pdfThankYou, style: const pw.TextStyle(color: PdfColors.grey)),
          ),
        ];
      }
    });
''';
  
  int startCall = currentContent.indexOf('_addPages(doc, options, textDir, watermarkBg, buildFooter: (context) => _buildDocumentFooter(');
  int endCall = currentContent.indexOf(']);', startCall) + 3;
  currentContent = currentContent.replaceRange(startCall, endCall, oldAddPagesCall);
  
  // _addPages definition
  currentContent = currentContent.replaceAll(
    'void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, List<pw.Widget> Function() buildContent, {pw.Widget Function(pw.Context)? buildFooter}) {',
    'void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, bool isFacture, List<pw.Widget> Function() buildContent, {pw.Widget Function(pw.Context)? buildFooter}) {'
  );

  // Replace background builder
  currentContent = currentContent.replaceFirst(
    'pw.Widget backgroundBuilder(pw.Context context) {',
    'pw.Widget backgroundBuilder(pw.Context context) {\n      if (!isFacture) return pw.Container(color: PdfColors.white);'
  );

  // Replace margins
  currentContent = currentContent.replaceAll(
    'margin: const pw.EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 24),',
    'margin: isFacture ? const pw.EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 24) : const pw.EdgeInsets.all(24),'
  );
  currentContent = currentContent.replaceAll(
    'margin: const pw.EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 32),',
    'margin: isFacture ? const pw.EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 32) : const pw.EdgeInsets.all(32),'
  );

  // Note: we also have generatePurchasePdf which calls _addPages. We need to fix its call too!
  currentContent = currentContent.replaceAll(
    '_addPages(doc, options, textDir, watermarkBg, buildFooter: (context) => _buildDocumentFooter(companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone), () => [',
    '_addPages(doc, options, textDir, watermarkBg, false, buildFooter: null, () => ['
  );

  currentFile.writeAsStringSync(currentContent);
  print('Done merging.');
}
