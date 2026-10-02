with open('lib/src/presentation/settings/garbage_screen.dart', 'r') as f:
    lines = f.readlines()

new_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    new_lines.append(line)
    if "buildSubtitle: (invoice) {" in line:
        new_lines.insert(-1, "                  onEdit: (e) async { final db = ref.read(databaseProvider); final client = e.clientId != null ? await (db.select(db.clients)..where((t) => t.id.equals(e.clientId!))).getSingleOrNull() : null; await onEditInvoice(e, client, db); },\n")
    elif "buildSubtitle: (purchase) {" in line:
        new_lines.insert(-1, "                  onEdit: (e) async { final db = ref.read(databaseProvider); final supplier = await (db.select(db.suppliers)..where((t) => t.id.equals(e.supplierId))).getSingleOrNull(); await onEditPurchase(e, supplier, db); },\n")
    i += 1
    
with open('lib/src/presentation/settings/garbage_screen.dart', 'w') as f:
    f.writelines(new_lines)
