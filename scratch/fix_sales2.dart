import 'dart:io';

void main() {
  final file = File('lib/src/application/sales/sales_service.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst('this.customClientIce,\n  });\n\nclass ReturnRequest', 'this.customClientIce,\n  });\n}\n\nclass ReturnRequest');
  file.writeAsStringSync(content);
}
