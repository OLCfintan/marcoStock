import re

with open("lib/src/application/documents/pdf_generator.dart", "r") as f:
    content = f.read()

content = content.replace("PdfGoogleFonts.amiriRegular()", "PdfGoogleFonts.cairoRegular()")
content = content.replace("PdfGoogleFonts.amiriBold()", "PdfGoogleFonts.cairoBold()")

# Fix the A5 theme override
old_theme = """.copyWith(defaultTextStyle: pw.TextStyle(fontSize: 8, font: font, fontBold: boldFont)) // reduce default font size for a5"""
new_theme = """.copyWith(defaultTextStyle: pw.TextStyle(fontSize: 8, font: font, fontBold: boldFont, fontFallback: [font]))"""

content = content.replace(old_theme, new_theme)

with open("lib/src/application/documents/pdf_generator.dart", "w") as f:
    f.write(content)

