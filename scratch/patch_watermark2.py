import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# Remove pw.Watermark to prevent 45-degree rotation!
old_bg = """            pw.Center(
              child: pw.Watermark(
                child: pw.Opacity(
                  opacity: 0.12, // Lower opacity so it blends better
                  child: pw.Image(bgImage, fit: pw.BoxFit.contain),
                ),
              ),
            ),"""
new_bg = """            pw.Positioned.fill(
              child: pw.Opacity(
                opacity: 0.20,
                child: pw.Image(bgImage, fit: pw.BoxFit.cover), // Cover the whole page!
              ),
            ),"""
content = content.replace(old_bg, new_bg)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("Watermark patched 2")
