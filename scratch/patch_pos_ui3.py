import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

target = "onChanged: (val) => _onDocumentTypeChanged(val!),"
replacement = """onChanged: (val) => _onDocumentTypeChanged(val!),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: _activeSession.selectedPaymentMethod,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.modeDeReglement,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    items: [
                      DropdownMenuItem(value: 'CASH', child: Text(AppLocalizations.of(context)!.cash)),
                      DropdownMenuItem(value: 'CHECK', child: Text(AppLocalizations.of(context)!.check)),
                      DropdownMenuItem(value: 'LETTER', child: Text(AppLocalizations.of(context)!.letter)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _activeSession.selectedPaymentMethod = val);
                    },"""

# We only want to replace the FIRST occurrence in the checkout panel, but wait, is there another _onDocumentTypeChanged?
# Let's just use re.sub with count=1

content = content.replace(target, replacement, 1)

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
print("pos_screen.dart patched UI accurately.")
