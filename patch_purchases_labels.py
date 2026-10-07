import sys

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("labelText: 'Quantity'", "labelText: AppLocalizations.of(context)?.quantity ?? 'Quantity'")
content = content.replace("labelText: 'Unit Cost'", "labelText: AppLocalizations.of(context)?.unitCost ?? 'Unit Cost'")
content = content.replace("labelText: 'Method'", "labelText: AppLocalizations.of(context)?.method ?? 'Method'")

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
