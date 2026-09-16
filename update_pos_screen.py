import re

filepath = "lib/src/presentation/sales/pos_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

# 1. Update default value
content = content.replace("String _selectedDocumentType = 'FACTURE';", "String _selectedDocumentType = 'BON';")

# 2. Swap dropdown items order
old_items = r"""                    items: \[
                      DropdownMenuItem\(value: 'FACTURE', child: Text\(AppLocalizations\.of\(context\)!\.invoice\)\),
                      DropdownMenuItem\(value: 'BON', child: Text\(AppLocalizations\.of\(context\)!\.bon\)\),
                    \],"""
                    
new_items = r"""                    items: [
                      DropdownMenuItem(value: 'BON', child: Text(AppLocalizations.of(context)!.bon)),
                      DropdownMenuItem(value: 'FACTURE', child: Text(AppLocalizations.of(context)!.invoice)),
                    ],"""
content = re.sub(old_items, new_items, content, flags=re.MULTILINE)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
