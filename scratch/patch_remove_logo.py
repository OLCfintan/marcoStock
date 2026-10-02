import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

old_block = """          children: [
            if (logoImage != null) 
              pw.Container(
                height: 100,
                constraints: const pw.BoxConstraints(maxWidth: 300),
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            _bidiText(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),"""

new_block = """          children: [
            _bidiText(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),"""

content = content.replace(old_block, new_block)

# Also do it for Purchases if there's a top-left logo there. Purchases use their own inline generation.
# Let's check `generatePurchasePdf` block.
old_purchase = """            pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null || watermarkBg != null) pw.Container(height: 80, constraints: const pw.BoxConstraints(maxWidth: 250), margin: const pw.EdgeInsets.only(bottom: 8), child: pw.Image(logoImage ?? watermarkBg!, fit: pw.BoxFit.contain)),
                    _bidiText(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),"""

new_purchase = """            pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _bidiText(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),"""

content = content.replace(old_purchase, new_purchase)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("Removed top-left logos")
