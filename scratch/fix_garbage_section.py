with open('lib/src/presentation/settings/garbage_screen.dart', 'r') as f:
    lines = f.readlines()

new_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    new_lines.append(line)
    if "(invoice) async {" in line and "await (_db.delete(_db.invoices)" in lines[i+1]:
        # we are at the onPermanentDelete
        new_lines.append(lines[i+1])
        new_lines.append(lines[i+2])
        new_lines.append("                  onEdit: (e) async {\n")
        new_lines.append("                    final client = e.clientId != null ? await (_db.select(_db.clients)..where((t) => t.id.equals(e.clientId!))).getSingleOrNull() : null;\n")
        new_lines.append("                    await onEditInvoice(e, client, _db);\n")
        new_lines.append("                  },\n")
        i += 2
    elif "(purchase) async {" in line and "await (_db.delete(_db.purchases)" in lines[i+1]:
        new_lines.append(lines[i+1])
        new_lines.append(lines[i+2])
        new_lines.append("                  onEdit: (e) async {\n")
        new_lines.append("                    final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(e.supplierId))).getSingleOrNull();\n")
        new_lines.append("                    await onEditPurchase(e, supplier, _db);\n")
        new_lines.append("                  },\n")
        i += 2
    i += 1
    
with open('lib/src/presentation/settings/garbage_screen.dart', 'w') as f:
    f.writelines(new_lines)
