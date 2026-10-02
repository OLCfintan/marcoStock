import 'dart:io';

void main() {
  final file = File('lib/src/application/purchases/purchase_service.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst('this.checkImagePath,\n  });\n\nclass PurchaseRequest', 'this.checkImagePath,\n  });\n}\n\nclass PurchaseRequest');
  content = content.replaceFirst('this.payments = const [],\n  });\n\nclass PurchaseLineRequest', 'this.payments = const [],\n  });\n}\n\nclass PurchaseLineRequest');
  content = content.replaceFirst('required this.unitPrice,\n  });\n\nclass PurchaseService', 'required this.unitPrice,\n  });\n}\n\nclass PurchaseService');
  file.writeAsStringSync(content);
}
