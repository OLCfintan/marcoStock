import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# Modify _addPages signature
old_sig = """  void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, bool isFacture, List<pw.Widget> Function() buildContent, {pw.Widget Function(pw.Context)? buildFooter}) {"""
new_sig = """  void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, bool isFacture, List<pw.Widget> Function() buildContent, {pw.Widget Function(pw.Context)? buildFooter, double bgOpacity = 0.20}) {"""
content = content.replace(old_sig, new_sig)

# Modify Opacity inside _addPages
old_opac = """            pw.Positioned.fill(
              child: pw.Opacity(
                opacity: 0.20,
                child: pw.Image(bgImage, fit: pw.BoxFit.cover), // Cover the whole page!
              ),
            ),"""
new_opac = """            pw.Positioned.fill(
              child: pw.Opacity(
                opacity: bgOpacity,
                child: pw.Center(child: pw.Image(bgImage, fit: pw.BoxFit.contain)), // contain is better for logos so they don't stretch out of bounds
              ),
            ),"""
content = content.replace(old_opac, new_opac)

# Modify generateInvoicePdf call
old_call = """    _addPages(doc, options, textDir, finalLogo ?? watermarkBg, isFactureDoc, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(companyInvoiceAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : (context) => _buildBonFooter(l10n), () {"""
new_call = """    _addPages(doc, options, textDir, finalLogo ?? watermarkBg, isFactureDoc, bgOpacity: finalLogo != null ? 0.12 : 1.0, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(companyInvoiceAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : (context) => _buildBonFooter(l10n), () {"""
content = content.replace(old_call, new_call)

# Modify generatePurchasePdf call
old_purch = """    _addPages(doc, options, textDir, watermarkBg, false, buildFooter: null, () => ["""
new_purch = """    _addPages(doc, options, textDir, watermarkBg, false, bgOpacity: 1.0, buildFooter: null, () => ["""
content = content.replace(old_purch, new_purch)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("Opacity patched")
