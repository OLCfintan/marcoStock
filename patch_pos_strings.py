import sys

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# Auto Invoice Generator dialog
content = content.replace("const Text('Auto Invoice Generator')", "Text(AppLocalizations.of(context)?.autoInvoiceGenerator ?? 'Auto Invoice Generator')")
content = content.replace("labelText: 'Target Amount (HT)'", "labelText: AppLocalizations.of(context)?.targetAmountHt ?? 'Target Amount (HT)'")
content = content.replace("labelText: 'Target Amount (TTC)'", "labelText: AppLocalizations.of(context)?.targetAmountTtc ?? 'Target Amount (TTC)'")
content = content.replace("labelText: 'Number of Families (Categories)'", "labelText: AppLocalizations.of(context)?.numberOfFamilies ?? 'Number of Families (Categories)'")
content = content.replace("const Text('Generate')", "Text(AppLocalizations.of(context)?.generate ?? 'Generate')")

# Cart strings
content = content.replace("'Cart 1'", "AppLocalizations.of(context)?.cartNumber('1') ?? 'Cart 1'")
content = content.replace("'Cart ${_sessions.length + 1}'", "AppLocalizations.of(context)?.cartNumber('${_sessions.length + 1}') ?? 'Cart ${_sessions.length + 1}'")
content = content.replace("Tab(text: 'Cart')", "Tab(text: AppLocalizations.of(context)?.cartTitle ?? 'Cart')")

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
