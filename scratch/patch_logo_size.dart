import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  // Replace the size of the logo container
  content = content.replaceFirst(
    'pw.Container(\n                width: 100,\n                height: 60,',
    'pw.Container(\n                width: 200,\n                height: 120,'
  );

  content = content.replaceFirst(
    'pw.SizedBox(width: 100),',
    'pw.SizedBox(width: 200),'
  );

  file.writeAsStringSync(content);
}
