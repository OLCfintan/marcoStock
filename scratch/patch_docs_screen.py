with open('lib/src/presentation/documents/documents_screen.dart', 'r') as f:
    content = f.read()

import re

old_purch = "      final query = (db.select(db.purchases)\n        ..where((t) => t.isActive.equals(true))).join(["
new_purch = "      final query = (db.select(db.purchases)\n        ..where((t) => t.isActive.equals(true) & t.documentType.isNotIn(['FACTURE', 'FACTURE_DUMMY', 'COMMANDE']))).join(["

old_inv = "      final query = (db.select(db.invoices)\n        ..where((t) => t.isActive.equals(true))).join(["
new_inv = "      final query = (db.select(db.invoices)\n        ..where((t) => t.isActive.equals(true) & t.documentType.isNotIn(['FACTURE', 'FACTURE_DUMMY', 'COMMANDE']))).join(["

content = content.replace(old_purch, new_purch)
content = content.replace(old_inv, new_inv)

with open('lib/src/presentation/documents/documents_screen.dart', 'w') as f:
    f.write(content)
print("Docs screen patched")
