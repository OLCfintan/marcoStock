import 'dart:io';

void main() {
  final file = File('lib/src/application/sales/sales_service.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst('this.payments = const [],\n  });\n\nclass SaleLineRequest', 'this.payments = const [],\n  });\n}\n\nclass SaleLineRequest');
  file.writeAsStringSync(content);
}
