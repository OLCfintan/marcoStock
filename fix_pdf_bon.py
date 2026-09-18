import re

filepath = "lib/src/application/documents/pdf_generator.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Change pdfBonTo and pdfBillTo to just say 'Client:' or l10n.client
content = content.replace("pw.Text(invoice.documentType == 'BON' ? l10n.pdfBonTo : l10n.pdfBillTo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),", "pw.Text('Client:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),")

# Remove remaining in bon/invoice
content = content.replace("pw.Text(invoice.documentType == 'BON' ? l10n.pdfRemainingInBon : l10n.pdfRemainingInInvoice", "pw.Text(l10n.pdfBalance")

with open(filepath, 'w') as f:
    f.write(content)
print("Updated PDF generator BON text")
