import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  // 1. Adjust margins
  content = content.replaceAll(
    "margin: const pw.EdgeInsets.all(24),",
    "margin: const pw.EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 24),"
  );
  content = content.replaceAll(
    "margin: const pw.EdgeInsets.all(32),",
    "margin: const pw.EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 32),"
  );

  // 2. Adjust logo container
  content = content.replaceAll(
    '''
            if (logoImage != null)
              pw.Container(
                width: 200,
                height: 120,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              )
            else
              pw.SizedBox(width: 200),''',
    '''
            if (logoImage != null)
              pw.Container(
                width: 200,
                constraints: const pw.BoxConstraints(maxHeight: 120),
                alignment: pw.Alignment.topCenter,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              )
            else
              pw.SizedBox(width: 200),'''
  );

  file.writeAsStringSync(content);
}
