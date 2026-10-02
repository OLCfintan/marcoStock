import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# 1. Restore the Marko Group top logo fallback
old_header_call = """_buildFactureHeader(invoice, client, finalCompanyName, companyInvoiceAddress, companyPhone, companyTaxId, companyIce, companyRc, companyRib, companyEmail, finalLogo, l10n)"""
new_header_call = """_buildFactureHeader(invoice, client, finalCompanyName, companyInvoiceAddress, companyPhone, companyTaxId, companyIce, companyRc, companyRib, companyEmail, finalLogo ?? watermarkBg, l10n)"""
content = content.replace(old_header_call, new_header_call)

# 2. Remove the harsh white container and add ClipRRect to the logo
old_header = """    return pw.Container(
      color: PdfColors.white,
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: ["""

new_header = """    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: ["""
content = content.replace(old_header, new_header)

old_end = """        ),
      ]),
    );
  }"""
new_end = """        ),
      ],
    );
  }"""
content = content.replace(old_end, new_end)

# 3. Add ClipRRect to the logo
old_logo = """            if (logoImage != null)
              pw.Container(
                height: 100,
                alignment: pw.Alignment.center,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              )"""

new_logo = """            if (logoImage != null)
              pw.Container(
                height: 100,
                alignment: pw.Alignment.center,
                child: pw.ClipRRect(
                  horizontalRadius: 16,
                  verticalRadius: 16,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              )"""
content = content.replace(old_logo, new_logo)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("Header restored and patched")
