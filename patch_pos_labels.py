import sys

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("labelText: 'Company Branch'", "labelText: AppLocalizations.of(context)?.companyBranch ?? 'Company Branch'")
content = content.replace("labelText: 'ICE'", "labelText: AppLocalizations.of(context)?.ice ?? 'ICE'")
content = content.replace("labelText: 'Scan Barcode'", "labelText: AppLocalizations.of(context)?.scanBarcode ?? 'Scan Barcode'")
content = content.replace("labelText: 'Select Client'", "labelText: AppLocalizations.of(context)?.selectClient ?? 'Select Client'")

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
