import 'dart:io';

void main() {
  final file = File('lib/src/application/sales/sales_service.dart');
  var content = file.readAsStringSync();
  
  final startMethod = content.indexOf('Future<String> getNextCustomInvoiceNumber(String prefix) async {');
  final endMethod = content.indexOf('return \'\${prefix}1\';\n  }', startMethod);
  
  if (startMethod == -1 || endMethod == -1) {
    print('Could not find method');
    return;
  }
  
  final newMethod = '''
  Future<String> getNextCustomInvoiceNumber(String prefix) async {
    final result = await _db.customSelect(
      "SELECT invoice_number FROM invoices WHERE invoice_number LIKE '\$prefix%'",
    ).get();

    int maxNum = 0;
    for (final row in result) {
      final str = row.read<String>('invoice_number');
      if (str.length > prefix.length) {
        final numPart = str.substring(prefix.length);
        final cleanNum = numPart.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanNum.isNotEmpty) {
          final num = int.tryParse(cleanNum) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
    }
    
    if (maxNum > 0) {
      return '\$prefix\${maxNum + 1}';
    }
    ''';
    
  content = content.replaceRange(startMethod, endMethod, newMethod);
  file.writeAsStringSync(content);
}
