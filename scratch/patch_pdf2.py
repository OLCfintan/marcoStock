import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# 1. Update exportAndSharePdf to read new settings, handle branch, and fix footer args
old_load = """    final companyAddress = settings['companyAddress'] ?? '';
    final companyPhone = settings['companyPhone'] ?? '';
    final companyTaxId = settings['companyTaxId'] ?? '';"""
new_load = """    final companyAddress = settings['companyAddress'] ?? '';
    final companyInvoiceAddress = settings['companyInvoiceAddress'] ?? companyAddress;
    final companyPhone = settings['companyPhone'] ?? '';
    final companyTaxId = settings['companyTaxId'] ?? '';
    final companyTp = settings['companyTp'] ?? '';"""
content = content.replace(old_load, new_load)

# Also need to read invoice.companyBranch in exportAndSharePdf
old_inv_read = """    final invoice = await (_db.select(_db.invoices)..where((tbl) => tbl.id.equals(invoiceId))).getSingle();
    final client = invoice.clientId != null ? await (_db.select(_db.clients)..where((tbl) => tbl.id.equals(invoice.clientId!))).getSingleOrNull() : null;"""
new_inv_read = """    final invoice = await (_db.select(_db.invoices)..where((tbl) => tbl.id.equals(invoiceId))).getSingle();
    final client = invoice.clientId != null ? await (_db.select(_db.clients)..where((tbl) => tbl.id.equals(invoice.clientId!))).getSingleOrNull() : null;
    
    // Override company details based on branch
    String finalCompanyName = companyName;
    pw.ImageProvider? finalLogo = logoImage;
    if (invoice.companyBranch == 'MARKO_PEINT') {
       finalCompanyName = 'Marko Peint';
       finalLogo = watermarkBg ?? logoImage; // Use the main logo that's usually watermark if any, but since the user said "the one that i select as my app logo", actually LogoLoader uses 'assets/images/logo.jpeg'.
       // Wait, logoImage is loaded from settings. The user said: "if select MarkoPeint show the one that i select as my app logo the one that appers when i first open the program".
       // The app logo is 'assets/images/logo.jpeg'. It is loaded via rootBundle in the watermarkBg.
       finalLogo = watermarkBg; 
    }"""
content = content.replace(old_inv_read, new_inv_read)

# Update buildFooter and _addPages calls
old_add1 = """_addPages(doc, options, textDir, watermarkBg, isFactureDoc, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone) : null, () {"""
new_add1 = """_addPages(doc, options, textDir, watermarkBg, isFactureDoc, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(isFactureDoc ? companyInvoiceAddress : companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : null, () {"""
content = content.replace(old_add1, new_add1)

# Inside _addPages callback:
old_call_head1 = """          _buildFactureHeader(finalCompanyName, finalLogo, isFactureDoc ? companyInvoiceAddress : companyAddress, companyPhone, companyTaxId, invoice),"""
old_call_head2 = """          _buildFactureHeader(companyName, logoImage, companyAddress, companyPhone, companyTaxId, invoice),"""
# I need to fix the parameters for _buildFactureHeader to use finalLogo and finalCompanyName
old_call1 = """          _buildFactureHeader(companyName, logoImage, companyAddress, companyPhone, companyTaxId, invoice),"""
new_call1 = """          _buildFactureHeader(finalCompanyName, finalLogo, isFactureDoc ? companyInvoiceAddress : companyAddress, companyPhone, companyTaxId, invoice),"""
content = content.replace(old_call1, new_call1)

old_call2 = """          _buildOldHeader(companyName, logoImage, companyAddress, companyPhone, companyTaxId, invoice, l10n),"""
new_call2 = """          _buildOldHeader(finalCompanyName, finalLogo, isFactureDoc ? companyInvoiceAddress : companyAddress, companyPhone, companyTaxId, invoice, l10n),"""
content = content.replace(old_call2, new_call2)


# 2. _buildDocumentFooter
old_foot_sig = """  pw.Widget _buildDocumentFooter(String companyAddress, String companyIce, String companyRc, String companyRib, String companyEmail, String companyPhone) {"""
new_foot_sig = """  pw.Widget _buildDocumentFooter(String companyAddress, String companyIce, String companyRc, String companyRib, String companyEmail, String companyPhone, String companyTaxId, String companyTp) {"""
content = content.replace(old_foot_sig, new_foot_sig)

old_foot_line = """          child: _bidiText('RIB : $companyRib | ICE : $companyIce | RC : $companyRc | Email : $companyEmail', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),"""
new_foot_line = """          child: _bidiText('RIB : $companyRib | ICE : $companyIce | RC : $companyRc | IF : $companyTaxId | TP : $companyTp', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          alignment: pw.Alignment.center,
          child: _bidiText('Email : $companyEmail', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),"""
content = content.replace(old_foot_line, new_foot_line)


# 3. Fix _addPages Background
old_bg = """    pw.Widget backgroundBuilder(pw.Context context) {
      if (!isFacture) return pw.Container(color: PdfColors.white);
      if (bgImage == null) {"""
new_bg = """    pw.Widget backgroundBuilder(pw.Context context) {
      if (bgImage == null) {"""
content = content.replace(old_bg, new_bg)


# 4. Fix _buildFactureHeader top logo constraint
old_top_logo = """            if (logoImage != null)
              pw.Container(
                width: 200,
                constraints: const pw.BoxConstraints(maxHeight: 120),
                alignment: pw.Alignment.topCenter,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              )
            else"""
new_top_logo = """            if (logoImage != null)
              pw.Container(
                height: 100,
                alignment: pw.Alignment.center,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              )
            else"""
content = content.replace(old_top_logo, new_top_logo)


# 5. Fix _buildOldHeader to use the new companyAddress (and ensure no top logo)
# Wait, I already removed the top logo from _buildOldHeader earlier!
# But let's check `generatePurchasePdf`.
old_purch_load = """    final companyAddress = settings['companyAddress'] ?? '';
    final companyPhone = settings['companyPhone'] ?? '';
    final companyTaxId = settings['companyTaxId'] ?? '';"""
new_purch_load = """    final companyAddress = settings['companyAddress'] ?? '';
    final companyInvoiceAddress = settings['companyInvoiceAddress'] ?? companyAddress;
    final companyPhone = settings['companyPhone'] ?? '';
    final companyTaxId = settings['companyTaxId'] ?? '';
    final companyTp = settings['companyTp'] ?? '';"""
content = content.replace(old_purch_load, new_purch_load)

# Wait, `generatePurchasePdf` doesn't use `_buildDocumentFooter`.
# Let's save.

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("pdf_generator patched")
