import 'dart:io';

void main() {
  final file = File('lib/src/presentation/documents/documents_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    'Future<void> _handlePrintInvoice(dynamic invoice, BuildContext context) async {',
    'Future<void> _handlePrintInvoice(dynamic invoice, BuildContext context, WidgetRef ref) async {'
  );
  
  content = content.replaceAll(
    '_handlePrintInvoice(invoice, context);',
    '_handlePrintInvoice(invoice, context, ref);'
  );
  
  file.writeAsStringSync(content);
}
