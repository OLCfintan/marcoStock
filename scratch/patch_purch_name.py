import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

old = """    final companyNameRaw = companySettings['companyName'] ?? 'Marko Group';
    final companyAddress = companySettings['companyAddress'] ?? '';
    final companyInvoiceAddress = companySettings['companyInvoiceAddress'] ?? companyAddress;
    final companyPhone = companySettings['companyPhone'] ?? '';
    final companyTaxId = companySettings['companyTaxId'] ?? '';
    final companyTp = companySettings['companyTp'] ?? '';


    final textDir = l10n.localeName.startsWith('ar') ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    pw.ImageProvider? watermarkBg;"""
    
new = """    final companyName = companySettings['companyName'] ?? 'Marko Group';
    final companyAddress = companySettings['companyAddress'] ?? '';
    final companyInvoiceAddress = companySettings['companyInvoiceAddress'] ?? companyAddress;
    final companyPhone = companySettings['companyPhone'] ?? '';
    final companyTaxId = companySettings['companyTaxId'] ?? '';
    final companyTp = companySettings['companyTp'] ?? '';


    final textDir = l10n.localeName.startsWith('ar') ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    pw.ImageProvider? watermarkBg;"""

# Wait, the search string might match generateInvoicePdf too! Let's restrict to generatePurchasePdf.
# generatePurchasePdf is around line 270.
