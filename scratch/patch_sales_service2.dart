import 'dart:io';

void main() {
  final file = File('lib/src/application/sales/sales_service.dart');
  var content = file.readAsStringSync();
  
  // 1. Patch executeSale
  content = content.replaceFirst(
    '''
      if (request.documentType == 'FACTURE' && request.customInvoiceNumber != null && request.customInvoiceNumber!.isNotEmpty) {
        invoiceNumber = request.customInvoiceNumber!;
      } else {
        final yearMonth = '\${date.year}-\${date.month.toString().padLeft(2, '0')}';''',
    '''
      if (request.documentType == 'FACTURE' && request.customInvoiceNumber != null && request.customInvoiceNumber!.isNotEmpty) {
        invoiceNumber = request.customInvoiceNumber!;
      } else if (request.documentType == 'FACTURE' || request.documentType == 'FACTURE_DUMMY') {
        final settings = await _db.customSelect('SELECT value FROM settings WHERE key = ?', variables: [const drift.Variable.withString('invoiceCounterPrefix')]).getSingleOrNull();
        final prefixSetting = settings?.read<String>('value') ?? 'MG';
        invoiceNumber = await getNextCustomInvoiceNumber(prefixSetting);
      } else {
        final yearMonth = '\${date.year}-\${date.month.toString().padLeft(2, '0')}';'''
  );

  // 2. Patch convertBonToInvoice
  final startConvert = content.indexOf('if (customInvoiceNumber != null && customInvoiceNumber.isNotEmpty) {', content.indexOf('Future<void> convertBonToInvoice'));
  final endConvert = content.indexOf('final newInvoiceId = _uuid.v4();', startConvert);
  
  final newConvertBlock = '''
      if (customInvoiceNumber != null && customInvoiceNumber.isNotEmpty) {
        invoiceNumber = customInvoiceNumber;
      } else {
        final settings = await _db.customSelect('SELECT value FROM settings WHERE key = ?', variables: [const drift.Variable.withString('invoiceCounterPrefix')]).getSingleOrNull();
        final prefixSetting = settings?.read<String>('value') ?? 'MG';
        invoiceNumber = await getNextCustomInvoiceNumber(prefixSetting);
      }

      ''';
      
  content = content.replaceRange(startConvert, endConvert, newConvertBlock);

  file.writeAsStringSync(content);
}
