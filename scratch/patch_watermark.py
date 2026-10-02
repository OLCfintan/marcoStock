import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# Change watermark opacity and remove fixed size from _buildFactureHeader logo if it exists
old_bg = """            pw.Center(
              child: pw.Watermark(
                child: pw.Opacity(
                  opacity: 0.25,
                  child: pw.Image(bgImage, fit: pw.BoxFit.contain),
                ),
              ),
            ),"""
new_bg = """            pw.Center(
              child: pw.Watermark(
                child: pw.Opacity(
                  opacity: 0.12, // Lower opacity so it blends better
                  child: pw.Image(bgImage, fit: pw.BoxFit.contain),
                ),
              ),
            ),"""
content = content.replace(old_bg, new_bg)

# Fix Bon Footer positioning
old_bon_end = """          _buildOldTotals(invoice, l10n),
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Container(
            alignment: pw.Alignment.center,
            child: _bidiText(l10n.pdfThankYou, style: const pw.TextStyle(color: PdfColors.grey)),
          ),
        ];"""
new_bon_end = """          _buildOldTotals(invoice, l10n),
        ];"""
content = content.replace(old_bon_end, new_bon_end)

# Pass the footer properly
old_add_pages = """    _addPages(doc, options, textDir, finalLogo ?? watermarkBg, isFactureDoc, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(isFactureDoc ? companyInvoiceAddress : companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : null, () {"""
new_add_pages = """    _addPages(doc, options, textDir, finalLogo ?? watermarkBg, isFactureDoc, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(companyInvoiceAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : (context) => _buildBonFooter(l10n), () {"""
content = content.replace(old_add_pages, new_add_pages)

# Add _buildBonFooter function
old_foot_func = """  pw.Widget _buildDocumentFooter(String companyAddress, String companyIce, String companyRc, String companyRib, String companyEmail, String companyPhone, String companyTaxId, String companyTp) {"""
new_foot_func = """  pw.Widget _buildBonFooter(AppLocalizations l10n) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 1, color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        pw.Container(
          alignment: pw.Alignment.center,
          child: _bidiText(l10n.pdfThankYou, style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10)),
        ),
      ],
    );
  }

  pw.Widget _buildDocumentFooter(String companyAddress, String companyIce, String companyRc, String companyRib, String companyEmail, String companyPhone, String companyTaxId, String companyTp) {"""
content = content.replace(old_foot_func, new_foot_func)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("Watermark patched")
