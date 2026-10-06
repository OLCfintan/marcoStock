import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# We need to add `onSubmitted: (_) => _processSale()` to TextField and `onFieldSubmitted: (_) => _processSale()` to TextFormField
# EXCEPT the ones inside the Edit Dialog (qty, price discount) and Barcode scanner!
# The ones inside Edit Dialog are around lines 995 and 1000. Let's do it carefully.
# Wait, it's easier to manually replace the ones we want.

fields = [
    "controller: invoiceCounterController,",
    "controller: invoiceDateController,",
    "controller: _activeSession.customNameController,",
    "controller: _activeSession.customIceController,",
    "controller: p.amountController,",
]

for field in fields:
    if "amountController" in field:
        # It's a TextField
        content = content.replace(field, field + "\n                                        onSubmitted: (_) => _processSale(),")
    else:
        # It's a TextFormField
        content = content.replace(field, field + "\n                            onFieldSubmitted: (_) => _processSale(),")

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
print("pos screen patched")
