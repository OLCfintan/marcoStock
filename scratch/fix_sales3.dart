import 'dart:io';

void main() {
  final file = File('lib/src/application/sales/sales_service.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst('required this.discount,\n  });\n\nclass SalesService', 'required this.discount,\n  });\n}\n\nclass SalesService');
  file.writeAsStringSync(content);
}
