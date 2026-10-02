import 'dart:io';

void main() {
  final file = File('lib/src/application/sales/sales_service.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst('this.checkImagePath,\n  });\n\nclass SaleRequest', 'this.checkImagePath,\n  });\n}\n\nclass SaleRequest');
  file.writeAsStringSync(content);
}
