import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

old_logic = """    String finalCompanyName = companyName;
    pw.ImageProvider? finalLogo = logoImage;
    if (invoice.companyBranch == 'MARKO_PEINT') {
        finalCompanyName = 'Marko Peint';
        finalLogo = markoPeintLogo;
    }
    
    _addPages(doc, options, textDir, finalLogo ?? watermarkBg, isFactureDoc, bgOpacity: finalLogo != null ? 0.12 : 1.0, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(companyInvoiceAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : (context) => _buildBonFooter(l10n), () {"""

new_logic = """    String finalCompanyName = companyName;
    pw.ImageProvider? finalLogo = logoImage;
    pw.ImageProvider? finalBg = watermarkBg;
    double finalOpacity = 1.0;
    
    if (invoice.companyBranch == 'MARKO_PEINT') {
        finalCompanyName = 'Marko Peint';
        finalLogo = markoPeintLogo;
        finalBg = markoPeintLogo;
        finalOpacity = 0.15;
    }
    
    _addPages(doc, options, textDir, finalBg, isFactureDoc, bgOpacity: finalOpacity, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(companyInvoiceAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : (context) => _buildBonFooter(l10n), () {"""
content = content.replace(old_logic, new_logic)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("Opacity logic patched")
