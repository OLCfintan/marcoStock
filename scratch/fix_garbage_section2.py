with open('lib/src/presentation/settings/garbage_screen.dart', 'r') as f:
    content = f.read()
    
# Clean up any messed up _db insertions if any
content = content.replace("onEdit: (e) async {", "")
content = content.replace("final client = e.clientId != null ? await (_db.select(_db.clients)..where((t) => t.id.equals(e.clientId!))).getSingleOrNull() : null;", "")
content = content.replace("await onEditInvoice(e, client, _db);", "")

content = content.replace("final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(e.supplierId))).getSingleOrNull();", "")
content = content.replace("await onEditPurchase(e, supplier, _db);", "")

content = content.replace("buildSubtitle: (invoice) => Text", "onEdit: (e) async { final db = ref.read(databaseProvider); final client = e.clientId != null ? await (db.select(db.clients)..where((t) => t.id.equals(e.clientId!))).getSingleOrNull() : null; await onEditInvoice(e, client, db); }, buildSubtitle: (invoice) => Text")

content = content.replace("buildSubtitle: (purchase) => Text", "onEdit: (e) async { final db = ref.read(databaseProvider); final supplier = await (db.select(db.suppliers)..where((t) => t.id.equals(e.supplierId))).getSingleOrNull(); await onEditPurchase(e, supplier, db); }, buildSubtitle: (purchase) => Text")

with open('lib/src/presentation/settings/garbage_screen.dart', 'w') as f:
    f.write(content)
