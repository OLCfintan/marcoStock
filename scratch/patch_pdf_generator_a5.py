import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# Remove a4_2up block
pattern = r'    if \(options\.layout == PrintLayout\.a4_2up\) \{.*?(?=    \} else \{)'
content = re.sub(pattern, '', content, flags=re.DOTALL)

# Remove "} else {" and matching "}"
content = content.replace('    } else {\n      doc.addPage(', '    doc.addPage(')

# Now we need to remove the closing brace of the else block. It's right before "  }" of _addPages.
# Let's do it carefully.
content = content.replace('      );\n    }\n  }\n', '      );\n  }\n')

# Now modify the PageTheme to include scaling for A5
old_theme = '''          pageTheme: pw.PageTheme(
            pageFormat: options.layout == PrintLayout.a5 ? PdfPageFormat.a5 : PdfPageFormat.a4,
            textDirection: textDir,
            margin: isFacture ? const pw.EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 32) : const pw.EdgeInsets.all(32),
            buildBackground: backgroundBuilder,
          ),'''

new_theme = '''          pageTheme: pw.PageTheme(
            pageFormat: options.layout == PrintLayout.a5 ? PdfPageFormat.a5 : PdfPageFormat.a4,
            textDirection: textDir,
            margin: options.layout == PrintLayout.a5 
                ? (isFacture ? const pw.EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16) : const pw.EdgeInsets.all(16))
                : (isFacture ? const pw.EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 32) : const pw.EdgeInsets.all(32)),
            buildBackground: backgroundBuilder,
            theme: options.layout == PrintLayout.a5 
                ? pw.ThemeData.withFont(
                    base: pw.Font.helvetica(),
                    bold: pw.Font.helveticaBold(),
                    italic: pw.Font.helveticaOblique(),
                    boldItalic: pw.Font.helveticaBoldOblique(),
                  ).copyWith(defaultTextStyle: pw.TextStyle(fontSize: 8)) // reduce default font size for a5
                : pw.ThemeData.withFont(),
          ),'''

content = content.replace(old_theme, new_theme)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("PDF generator patched")
