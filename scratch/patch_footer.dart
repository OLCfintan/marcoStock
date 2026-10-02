import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  // 1. Update _addPages signature
  content = content.replaceFirst(
    'void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, List<pw.Widget> Function() buildContent) {',
    'void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, List<pw.Widget> Function() buildContent, {pw.Widget Function(pw.Context)? buildFooter}) {'
  );

  // 2. Add buildFooter to pw.Page's PageTheme
  content = content.replaceFirst(
    '''
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4.landscape,
            textDirection: textDir,
            margin: const pw.EdgeInsets.all(24),
            buildBackground: backgroundBuilder,
          ),''',
    '''
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4.landscape,
            textDirection: textDir,
            margin: const pw.EdgeInsets.all(24),
            buildBackground: backgroundBuilder,
            buildFooter: buildFooter,
          ),'''
  );

  // 3. Add footer to pw.MultiPage
  content = content.replaceFirst(
    '''
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: options.layout == PrintLayout.a5 ? PdfPageFormat.a5 : PdfPageFormat.a4,
            textDirection: textDir,
            margin: const pw.EdgeInsets.all(32),
            buildBackground: backgroundBuilder,
          ),
          build: (context) => buildContent(),
        ),''',
    '''
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: options.layout == PrintLayout.a5 ? PdfPageFormat.a5 : PdfPageFormat.a4,
            textDirection: textDir,
            margin: const pw.EdgeInsets.all(32),
            buildBackground: backgroundBuilder,
          ),
          footer: buildFooter,
          build: (context) => buildContent(),
        ),'''
  );

  // 4. Update generateInvoicePdf call
  content = content.replaceFirst(
    '_addPages(doc, options, textDir, watermarkBg, () => [',
    '''_addPages(doc, options, textDir, watermarkBg, buildFooter: (context) => _buildDocumentFooter(companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone), () => ['''
  );

  // 5. Update generatePurchasePdf call
  content = content.replaceFirst(
    '_addPages(doc, options, textDir, watermarkBg, () => [',
    '''_addPages(doc, options, textDir, watermarkBg, buildFooter: (context) => _buildDocumentFooter(companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone), () => ['''
  );

  // 6. Extract the footer from _buildTotals
  final startTotalsFooter = content.indexOf('pw.SizedBox(height: 30),\n        pw.Divider(thickness: 2, color: PdfColor.fromHex(\'#C5A059\')),');
  final endTotalsFooter = content.indexOf('pw.Widget _buildTotalRow(');
  if (startTotalsFooter != -1) {
    // We want to delete from pw.SizedBox(height: 30) up to the end of _buildTotals (which is `      ]\n    );\n  }`)
    // The exact string to replace is from startTotalsFooter to `  }\n\n  pw.Widget _buildTotalRow`
    
    // Find `  }\n\n  pw.Widget _buildTotalRow`
    final replaceEnd = endTotalsFooter;
    
    content = content.replaceRange(startTotalsFooter, replaceEnd, '      ]\n    );\n  }\n\n');
  }

  // 7. Add _buildDocumentFooter
  final newFooterStr = '''
  pw.Widget _buildDocumentFooter(String companyAddress, String companyIce, String companyRc, String companyRib, String companyEmail, String companyPhone) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Divider(thickness: 2, color: PdfColor.fromHex('#C5A059')),
        pw.SizedBox(height: 2),
        pw.Divider(thickness: 1, color: PdfColor.fromHex('#C5A059')),
        pw.SizedBox(height: 4),
        pw.Container(
          alignment: pw.Alignment.center,
          child: _bidiText('SIEGE SOCIAL : \$companyAddress', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#C5A059'), fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          alignment: pw.Alignment.center,
          child: _bidiText('RIB : \$companyRib | ICE : \$companyIce | RC : \$companyRc | Email : \$companyEmail', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          alignment: pw.Alignment.center,
          child: _bidiText(companyPhone, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

''';
  
  content = content.replaceFirst('pw.Widget _buildTotalRow', newFooterStr + 'pw.Widget _buildTotalRow');

  file.writeAsStringSync(content);
}
