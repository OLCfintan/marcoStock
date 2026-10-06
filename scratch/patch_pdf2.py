import sys

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

content = content.replace(
    "void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, bool isFacture, List<pw.Widget> Function() buildContent, {pw.Widget Function(pw.Context)? buildFooter, double bgOpacity = 0.25, pw.BoxFit bgFit = pw.BoxFit.cover}) {",
    "void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, bool isFacture, pw.Font font, pw.Font boldFont, List<pw.Widget> Function() buildContent, {pw.Widget Function(pw.Context)? buildFooter, double bgOpacity = 0.25, pw.BoxFit bgFit = pw.BoxFit.cover}) {"
)

content = content.replace(
"""            theme: options.layout == PrintLayout.a5 
                ? pw.ThemeData.withFont(
                    base: pw.Font.helvetica(),
                    bold: pw.Font.helveticaBold(),
                    italic: pw.Font.helveticaOblique(),
                    boldItalic: pw.Font.helveticaBoldOblique(),
                  ).copyWith(defaultTextStyle: pw.TextStyle(fontSize: 8)) // reduce default font size for a5
                : pw.ThemeData.withFont(),""",
"""            theme: options.layout == PrintLayout.a5 
                ? pw.ThemeData.withFont(
                    base: font,
                    bold: boldFont,
                  ).copyWith(defaultTextStyle: pw.TextStyle(fontSize: 8, font: font, fontBold: boldFont)) // reduce default font size for a5
                : null,"""
)

content = content.replace(
    "_addPages(doc, options, textDir, finalBg, isFactureDoc, bgOpacity: finalOpacity, bgFit: finalBgFit, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(companyInvoiceAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : (context) => _buildBonFooter(l10n), () {",
    "_addPages(doc, options, textDir, finalBg, isFactureDoc, font, boldFont, bgOpacity: finalOpacity, bgFit: finalBgFit, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(companyInvoiceAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : (context) => _buildBonFooter(l10n), () {"
)

content = content.replace(
    "_addPages(doc, options, textDir, watermarkBg, false, bgOpacity: 0.25, buildFooter: null, () => [",
    "_addPages(doc, options, textDir, watermarkBg, false, font, boldFont, bgOpacity: 0.25, buildFooter: null, () => ["
)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("Success")
