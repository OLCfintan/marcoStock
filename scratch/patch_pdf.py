import sys

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# find _addPages definition
target_def = "void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, bool isFacture, List<pw.Widget> Function() buildContent, {pw.Widget Function(pw.Context)? buildFooter, double bgOpacity = 0.25, pw.BoxFit bgFit = pw.BoxFit.cover}) {"
replacement_def = "void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, bool isFacture, List<pw.Widget> Function() buildContent, pw.Font font, pw.Font boldFont, {pw.Widget Function(pw.Context)? buildFooter, double bgOpacity = 0.25, pw.BoxFit bgFit = pw.BoxFit.cover}) {"

if target_def in content:
    content = content.replace(target_def, replacement_def)
    print("Replaced _addPages definition")
else:
    print("Failed to replace _addPages definition")

target_theme = """            theme: options.layout == PrintLayout.a5 
                ? pw.ThemeData.withFont(
                    base: pw.Font.helvetica(),
                    bold: pw.Font.helveticaBold(),
                    italic: pw.Font.helveticaOblique(),
                    boldItalic: pw.Font.helveticaBoldOblique(),
                  ).copyWith(defaultTextStyle: pw.TextStyle(fontSize: 8)) // reduce default font size for a5
                : pw.ThemeData.withFont(),"""

replacement_theme = """            theme: options.layout == PrintLayout.a5 
                ? pw.ThemeData.withFont(
                    base: font,
                    bold: boldFont,
                  ).copyWith(defaultTextStyle: pw.TextStyle(fontSize: 8, font: font, fontBold: boldFont)) // reduce default font size for a5
                : null,"""

if target_theme in content:
    content = content.replace(target_theme, replacement_theme)
    print("Replaced _addPages theme")
else:
    print("Failed to replace _addPages theme")

# Update calls to _addPages
content = content.replace("_addPages(doc, options, textDir, finalBg, isFactureDoc, bgOpacity: finalOpacity, bgFit: finalBgFit, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(companyInvoiceAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone, companyTaxId, companyTp) : (context) => _buildBonFooter(l10n), () {", "_addPages(doc, options, textDir, finalBg, isFactureDoc, () {", 1)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
