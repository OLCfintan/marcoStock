import re

filepath = "lib/src/application/documents/pdf_generator.dart"
with open(filepath, 'r') as f:
    content = f.read()

# 1. Remove Tax line
content = re.sub(r"            _buildTotalRow\('\$\{l10n\.pdfTax\}:', invoice\.taxes\.toStringAsFixed\(2\)\),\n", "", content)

# 2. Change document balance string in invoice summary
content = content.replace("_buildTotalRow('${l10n.pdfBalance}:'", "_buildTotalRow('${invoice.documentType == 'BON' ? l10n.pdfRemainingInBon : l10n.pdfRemainingInInvoice}:'")

# 3. Change client/supplier overall balance string to pdfTotalDebt
# Client in _buildHeader
content = content.replace("pw.Text('${l10n.pdfBalance}: ${client.balance.toStringAsFixed(2)} Dhs'", "pw.Text('${l10n.pdfTotalDebt}: ${client.balance.toStringAsFixed(2)} Dhs'")
# Supplier in generatePurchasePdf
content = content.replace("pw.Text('${l10n.pdfBalance}: ${supplier.balance.toStringAsFixed(2)} Dhs'", "pw.Text('${l10n.pdfTotalDebt}: ${supplier.balance.toStringAsFixed(2)} Dhs'")

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
