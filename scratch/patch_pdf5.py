import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# Make footer visible on FACTURES only
old_add_pages = """    _addPages(doc, options, textDir, watermarkBg, isFactureDoc, buildFooter: (context) => _buildDocumentFooter(isFactureDoc ? companyInvoiceAddress : companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp), () {"""
new_add_pages = """    _addPages(doc, options, textDir, watermarkBg, isFactureDoc, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(isFactureDoc ? companyInvoiceAddress : companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : null, () {"""

content = content.replace(old_add_pages, new_add_pages)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("pdf patched 5")
