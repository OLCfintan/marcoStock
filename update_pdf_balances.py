import re

filepath = "lib/src/application/documents/pdf_generator.dart"
with open(filepath, 'r') as f:
    content = f.read()

# 1. Invoice Client Balance
old_client = r"""            pw\.Text\(client\?\.name \?\? 'N/A', style: pw\.TextStyle\(fontWeight: pw\.FontWeight\.bold, fontSize: 14\)\),
            if \(client\?\.address != null && client!\.address!\.isNotEmpty\) pw\.Text\(client\.address!\),
            if \(client\?\.contactDetails != null && client!\.contactDetails!\.isNotEmpty\) pw\.Text\(client\.contactDetails!\),"""

new_client = r"""            pw.Text(client?.name ?? 'N/A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            if (client?.address != null && client!.address!.isNotEmpty) pw.Text(client.address!),
            if (client?.contactDetails != null && client!.contactDetails!.isNotEmpty) pw.Text(client.contactDetails!),
            if (client != null) pw.Text('${l10n.pdfBalance}: ${client.balance.toStringAsFixed(2)} Dhs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),"""

content = re.sub(old_client, new_client, content, flags=re.MULTILINE)

# 2. Purchase Supplier Balance
old_supplier = r"""                    pw\.Text\(supplier\?\.name \?\? 'N/A', style: pw\.TextStyle\(fontWeight: pw\.FontWeight\.bold, fontSize: 14\)\),"""

new_supplier = r"""                    pw.Text(supplier?.name ?? 'N/A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    if (supplier != null) pw.Text('${l10n.pdfBalance}: ${supplier.balance.toStringAsFixed(2)} Dhs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),"""

content = re.sub(old_supplier, new_supplier, content, flags=re.MULTILINE)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
