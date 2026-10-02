import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  // Remove buildFooter from PageTheme
  content = content.replaceAll(
    "buildBackground: backgroundBuilder,\n            buildFooter: buildFooter,\n          ),",
    "buildBackground: backgroundBuilder,\n          ),"
  );
  
  // Inject into pw.Page build method
  content = content.replaceAll(
    '''
          build: (context) {
            return pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: pw.Column(children: buildContent())),
                pw.SizedBox(width: 48),
                pw.Expanded(child: pw.Column(children: buildContent())),
              ],
            );
          },''',
    '''
          build: (context) {
            return pw.Column(
              children: [
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(child: pw.Column(children: buildContent())),
                      pw.SizedBox(width: 48),
                      pw.Expanded(child: pw.Column(children: buildContent())),
                    ],
                  ),
                ),
                if (buildFooter != null) buildFooter(context)
              ]
            );
          },'''
  );
  
  file.writeAsStringSync(content);
}
