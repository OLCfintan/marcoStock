import 'dart:io';

void main() {
  var content = File('lib/src/application/sales/sales_service.dart').readAsStringSync();
  print(content.contains('Future<String> getNextCustomInvoiceNumber'));
}
