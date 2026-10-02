import 'dart:io';

void main() {
  final file = File('lib/src/presentation/documents/document_edit_helpers.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll('invoice.customInvoiceNumber != null', 'invoice.invoiceNumber != null');
  content = content.replaceAll('session.invoiceCounterController.text = invoice.customInvoiceNumber!', 'session.invoiceCounterController.text = invoice.invoiceNumber;');
  file.writeAsStringSync(content);
}
