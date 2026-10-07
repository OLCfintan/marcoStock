import sys

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("'Cart 1'", "AppLocalizations.of(context)?.cartNumber('1') ?? 'Cart 1'")
content = content.replace("'Cart ${_sessions.length + 1}'", "AppLocalizations.of(context)?.cartNumber('${_sessions.length + 1}') ?? 'Cart ${_sessions.length + 1}'")
content = content.replace("Tab(text: 'Purchase Cart')", "Tab(text: AppLocalizations.of(context)?.purchaseCart ?? 'Purchase Cart')")
content = content.replace("labelText: 'Amount'", "labelText: AppLocalizations.of(context)?.amount ?? 'Amount'")
content = content.replace("Text('Add ${_multiSelectedProductIds.length}')", "Text('${AppLocalizations.of(context)?.add ?? 'Add'} ${_multiSelectedProductIds.length}')")

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
