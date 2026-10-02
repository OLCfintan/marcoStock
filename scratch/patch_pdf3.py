import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# Fix loading settings in generateInvoicePdf
old_load_gen = """        final companyName = companySettings['companyName'] ?? 'Marko Group';
    final companyAddress = companySettings['companyAddress'] ?? '';
    final companyPhone = companySettings['companyPhone'] ?? '';
    final companyTaxId = companySettings['companyTaxId'] ?? '';"""
new_load_gen = """    final companyNameRaw = companySettings['companyName'] ?? 'Marko Group';
    final companyAddress = companySettings['companyAddress'] ?? '';
    final companyInvoiceAddress = companySettings['companyInvoiceAddress'] ?? companyAddress;
    final companyPhone = companySettings['companyPhone'] ?? '';
    final companyTaxId = companySettings['companyTaxId'] ?? '';
    final companyTp = companySettings['companyTp'] ?? '';"""
content = content.replace(old_load_gen, new_load_gen)

# Fix loading settings in generatePurchasePdf
old_load_purch = """        final companyName = companySettings['companyName'] ?? 'Marko Group';
    final companyAddress = companySettings['companyAddress'] ?? '';
    final companyPhone = companySettings['companyPhone'] ?? '';
    final companyTaxId = companySettings['companyTaxId'] ?? '';"""
new_load_purch = """    final companyNameRaw = companySettings['companyName'] ?? 'Marko Group';
    final companyAddress = companySettings['companyAddress'] ?? '';
    final companyInvoiceAddress = companySettings['companyInvoiceAddress'] ?? companyAddress;
    final companyPhone = companySettings['companyPhone'] ?? '';
    final companyTaxId = companySettings['companyTaxId'] ?? '';
    final companyTp = companySettings['companyTp'] ?? '';"""
content = content.replace(old_load_purch, new_load_purch)

# In generateInvoicePdf, calculate final names and logos based on branch
# Find the start of _addPages in generateInvoicePdf
old_add_pages = """    final textDir = l10n.localeName.startsWith('ar') ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    pw.ImageProvider? watermarkBg;"""
new_add_pages = """    final textDir = l10n.localeName.startsWith('ar') ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    pw.ImageProvider? watermarkBg;
    pw.ImageProvider? markoPeintLogo;
    try {
      final file = File('assets/images/logo.jpeg');
      if (file.existsSync()) {
        markoPeintLogo = pw.MemoryImage(file.readAsBytesSync());
      } else {
        final ByteData data = await rootBundle.load('assets/images/logo.jpeg');
        markoPeintLogo = pw.MemoryImage(data.buffer.asUint8List());
      }
    } catch (e) {
      print('Could not load marko peint logo: $e');
    }"""
content = content.replace(old_add_pages, new_add_pages)

old_facture_logic = """        final isFactureDoc = invoice.documentType == 'FACTURE' || invoice.documentType == 'FACTURE_DUMMY';
    _addPages(doc, options, textDir, watermarkBg, isFactureDoc, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(isFactureDoc ? companyInvoiceAddress : companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : null, () {"""
new_facture_logic = """        final isFactureDoc = invoice.documentType == 'FACTURE' || invoice.documentType == 'FACTURE_DUMMY';
    
    String finalCompanyName = companyNameRaw;
    pw.ImageProvider? finalLogo = logoImage;
    if (invoice.companyBranch == 'MARKO_PEINT') {
        finalCompanyName = 'Marko Peint';
        finalLogo = markoPeintLogo;
    }
    
    _addPages(doc, options, textDir, watermarkBg, isFactureDoc, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(isFactureDoc ? companyInvoiceAddress : companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : null, () {"""
content = content.replace(old_facture_logic, new_facture_logic)

# Replace the calls inside _addPages
old_calls = """          _buildFactureHeader(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, companyIce, companyRc, companyRib, companyEmail, logoImage ?? watermarkBg, l10n),
          pw.SizedBox(height: 15),
          _buildFactureInvoiceTable(lines, productMap, l10n),
          pw.SizedBox(height: 15),
          _buildFactureTotals(invoice, l10n, companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone),
        ];
      } else {
        return [
          _buildOldHeader(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, logoImage ?? watermarkBg, l10n),"""
new_calls = """          _buildFactureHeader(invoice, client, finalCompanyName, companyInvoiceAddress, companyPhone, companyTaxId, companyIce, companyRc, companyRib, companyEmail, finalLogo ?? watermarkBg, l10n),
          pw.SizedBox(height: 15),
          _buildFactureInvoiceTable(lines, productMap, l10n),
          pw.SizedBox(height: 15),
          _buildFactureTotals(invoice, l10n, companyInvoiceAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone),
        ];
      } else {
        return [
          _buildOldHeader(invoice, client, finalCompanyName, companyAddress, companyPhone, companyTaxId, finalLogo ?? watermarkBg, l10n),"""
content = content.replace(old_calls, new_calls)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("pdf patched 3")
