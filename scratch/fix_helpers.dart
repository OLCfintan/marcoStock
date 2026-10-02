import 'dart:io';

void main() {
  final file = File('lib/src/presentation/documents/document_edit_helpers.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll('InvoiceData', 'InvoiceEntity');
  content = content.replaceAll('PurchaseData', 'PurchaseEntity');
  content = content.replaceAll('SupplierData', 'SupplierEntity');
  file.writeAsStringSync(content);
}
