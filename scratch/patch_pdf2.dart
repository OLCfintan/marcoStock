import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  final fetchSettings = '''
    final companyName = companySettings['companyName'] ?? 'Marko Group';
    final companyAddress = companySettings['companyAddress'] ?? '';
    final companyPhone = companySettings['companyPhone'] ?? '';
    final companyTaxId = companySettings['companyTaxId'] ?? '';
    final companyIce = companySettings['companyIce'] ?? '';
    final companyRc = companySettings['companyRc'] ?? '';
    final companyRib = companySettings['companyRib'] ?? '';
    final companyEmail = companySettings['companyEmail'] ?? '';
''';
  
  content = content.replaceAll(
    "final companyName = companySettings['companyName'] ?? 'Marko Group';\n    final companyAddress = companySettings['companyAddress'] ?? '';\n    final companyPhone = companySettings['companyPhone'] ?? '';\n    final companyTaxId = companySettings['companyTaxId'] ?? '';",
    fetchSettings
  );
  
  final headerCall = '''
      _buildHeader(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, companyIce, companyRc, companyRib, companyEmail, logoImage, l10n),
''';
  content = content.replaceAll(
    "_buildHeader(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, logoImage, l10n),",
    headerCall
  );
  
  file.writeAsStringSync(content);
}
