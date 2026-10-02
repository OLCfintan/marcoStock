import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  // Remove pageColor: PdfColors.white from PageTheme
  content = content.replaceAll(
    "margin: const pw.EdgeInsets.all(24),\n            pageColor: PdfColors.white,",
    "margin: const pw.EdgeInsets.all(24),"
  );
  content = content.replaceAll(
    "margin: const pw.EdgeInsets.all(32),\n            pageColor: PdfColors.white,",
    "margin: const pw.EdgeInsets.all(32),"
  );
  
  // To draw a white background, I can change backgroundBuilder to draw a white container behind the watermark
  content = content.replaceAll(
    '''
    pw.Widget backgroundBuilder(pw.Context context) {
      if (bgImage == null) return pw.Container();
      return pw.Watermark(
        child: pw.Opacity(
          opacity: 0.25,
          child: pw.Image(bgImage, fit: pw.BoxFit.contain),
        ),
      );
    }''',
    '''
    pw.Widget backgroundBuilder(pw.Context context) {
      if (bgImage == null) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: PdfColors.white),
        );
      }
      return pw.FullPage(
        ignoreMargins: true,
        child: pw.Stack(
          children: [
            pw.Container(color: PdfColors.white),
            pw.Center(
              child: pw.Watermark(
                child: pw.Opacity(
                  opacity: 0.25,
                  child: pw.Image(bgImage, fit: pw.BoxFit.contain),
                ),
              ),
            ),
          ],
        ),
      );
    }'''
  );

  file.writeAsStringSync(content);
}
