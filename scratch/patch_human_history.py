with open('lib/src/presentation/widgets/human_profile_dialog.dart', 'r') as f:
    content = f.read()

old_client = "stream: (db.select(db.invoices)..where((t) => t.clientId.equals(widget.id) & t.isActive.equals(true))..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])).watch(),"
new_client = "stream: (db.select(db.invoices)..where((t) => t.clientId.equals(widget.id) & t.isActive.equals(true) & t.documentType.isNotIn(['FACTURE', 'FACTURE_DUMMY', 'COMMANDE']))..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])).watch(),"

old_supplier = "stream: (db.select(db.purchases)..where((t) => t.supplierId.equals(widget.id) & t.isActive.equals(true))..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])).watch(),"
new_supplier = "stream: (db.select(db.purchases)..where((t) => t.supplierId.equals(widget.id) & t.isActive.equals(true) & t.documentType.isNotIn(['FACTURE', 'FACTURE_DUMMY', 'COMMANDE']))..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])).watch(),"

content = content.replace(old_client, new_client)
content = content.replace(old_supplier, new_supplier)

with open('lib/src/presentation/widgets/human_profile_dialog.dart', 'w') as f:
    f.write(content)
print("History patched")
