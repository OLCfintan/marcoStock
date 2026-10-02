import 'dart:io';

void main() {
  final file = File('lib/src/application/sales/sales_service.dart');
  var content = file.readAsStringSync();
  
  // Restore in SaleRequest
  content = content.replaceFirst(
    'final String? customClientName;\n  \n  SaleRequest({',
    'final String? customClientName;\n  final String? customClientIce;\n  \n  SaleRequest({'
  );
  content = content.replaceFirst(
    'this.customInvoiceNumber,\n    this.customDate,\n    this.customClientName,\n  });',
    'this.customInvoiceNumber,\n    this.customDate,\n    this.customClientName,\n    this.customClientIce,\n  });'
  );

  // Restore in executeSale
  content = content.replaceFirst(
    'clientNameOverride: drift.Value(request.customClientName),',
    'clientNameOverride: drift.Value(request.customClientName),\n        clientIceOverride: drift.Value(request.customClientIce),'
  );

  // Restore in convertBonToInvoice signature
  content = content.replaceFirst(
    'Future<void> convertBonToInvoice(String invoiceId, {String? customInvoiceNumber, DateTime? customDate, String? customName}) async {',
    'Future<void> convertBonToInvoice(String invoiceId, {String? customInvoiceNumber, DateTime? customDate, String? customName, String? customIce}) async {'
  );

  // Restore in convertBonToInvoice insertion
  content = content.replaceFirst(
    'clientNameOverride: drift.Value(customName),',
    'clientNameOverride: drift.Value(customName),\n        clientIceOverride: drift.Value(customIce),'
  );

  file.writeAsStringSync(content);
}
