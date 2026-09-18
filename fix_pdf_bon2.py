import re

filepath = "lib/src/application/documents/pdf_generator.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_total_row = r"""_buildTotalRow\('\$\{invoice.documentType == 'BON' \? l10n.pdfRemainingInBon : l10n.pdfRemainingInInvoice\}:', balance.toStringAsFixed\(2\), isBold: true, color: PdfColors.red700\),"""
new_total_row = r"""_buildTotalRow('${l10n.pdfBalance}:', balance.toStringAsFixed(2), isBold: true, color: PdfColors.red700),"""

content = re.sub(old_total_row, new_total_row, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated PDF generator BON remaining")
