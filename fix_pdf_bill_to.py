import re

filepath = "lib/src/application/documents/pdf_generator.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_bill_to = r"""pw\.Text\(l10n\.pdfBillTo, style: pw\.TextStyle\(fontWeight: pw\.FontWeight\.bold, color: PdfColors\.grey700\)\),"""
new_bill_to = r"""pw.Text(invoice.documentType == 'BON' ? l10n.pdfBonTo : l10n.pdfBillTo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),"""

content = re.sub(old_bill_to, new_bill_to, content)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
