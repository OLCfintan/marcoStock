import re

filepath = "lib/src/application/documents/pdf_generator.dart"
with open(filepath, 'r') as f:
    content = f.read()

# 1. Add companyPhone
content = content.replace("final String companyAddress = settings['companyAddress'] ?? '';", "final String companyAddress = settings['companyAddress'] ?? '';\n    final String companyPhone = settings['companyPhone'] ?? '';")

# Add to Header in _buildInvoiceHeader
content = content.replace("if (companyAddress.isNotEmpty) pw.Text(companyAddress),", "if (companyAddress.isNotEmpty) pw.Text(companyAddress),\n            if (companyPhone.isNotEmpty) pw.Text(companyPhone),")

# Add to Header in _buildPurchaseHeader
content = content.replace("if (companyAddress.isNotEmpty) pw.Text(companyAddress),\n                    if (companyTaxId.isNotEmpty)", "if (companyAddress.isNotEmpty) pw.Text(companyAddress),\n                    if (companyPhone.isNotEmpty) pw.Text(companyPhone),\n                    if (companyTaxId.isNotEmpty)")

# 2. Show Client Phone Number in Invoice PDF
client_details = """            if (client?.address != null && client!.address!.isNotEmpty) pw.Text(client.address!),
            if (client?.phone != null && client!.phone!.isNotEmpty) pw.Text(client.phone!),"""
content = re.sub(r"if \(client\?\.address != null && client!\.address!\.isNotEmpty\) pw\.Text\(client\.address!\),", client_details, content)


# 3. Remove discount param var from pdfs
old_invoice_table = r"""  pw.Widget _buildInvoiceTable\(List<InvoiceLineEntity> lines, Map<String, ProductEntity> productMap, AppLocalizations l10n\) \{
    return pw.TableHelper.fromTextArray\(
      headers: \[l10n.pdfItem, l10n.pdfQty, l10n.pdfPrice, l10n.pdfDiscount, l10n.pdfTotal\],
      data: lines.map\(\(line\) \{
        final product = productMap\[line.productId\];
        String productName = _localizedProductName\(product, l10n.localeName\);
        
        return \[
          productName,
          line.quantity.toStringAsFixed\(2\),
          line.unitPrice.toStringAsFixed\(2\),
          line.discount.toStringAsFixed\(2\),
          line.lineTotal.toStringAsFixed\(2\),
        \];
      \}\).toList\(\),"""

new_invoice_table = r"""  pw.Widget _buildInvoiceTable(List<InvoiceLineEntity> lines, Map<String, ProductEntity> productMap, AppLocalizations l10n) {
    return pw.TableHelper.fromTextArray(
      headers: [l10n.pdfItem, l10n.pdfQty, l10n.pdfPrice, l10n.pdfTotal],
      data: lines.map((line) {
        final product = productMap[line.productId];
        String productName = _localizedProductName(product, l10n.localeName);
        
        return [
          productName,
          line.quantity.toStringAsFixed(2),
          line.unitPrice.toStringAsFixed(2),
          line.lineTotal.toStringAsFixed(2),
        ];
      }).toList(),"""

content = re.sub(old_invoice_table, new_invoice_table, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated PDF generator")
