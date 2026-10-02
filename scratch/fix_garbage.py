with open('lib/src/presentation/settings/garbage_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("Future<void> Function(T) onPermanentDelete,", "Future<void> Function(T) onPermanentDelete,\n    {Future<void> Function(T)? onEdit,\n    Widget Function(T)? buildSubtitle}", 1)
content = content.replace("{Widget Function(T)? buildSubtitle}", "")

menu_str = """
                onSelected: (value) {
                  if (value == 'restore') onRestore(item);
                  if (value == 'delete_forever') onPermanentDelete(item);
                  if (value == 'edit' && onEdit != null) onEdit(item);
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)?.editStr ?? 'Edit')),
                  PopupMenuItem(value: 'restore', child: Text(AppLocalizations.of(context)!.restoreStr, style: const TextStyle(color: Colors.green))),
"""
content = content.replace("""
                onSelected: (value) {
                  if (value == 'restore') onRestore(item);
                  if (value == 'delete_forever') onPermanentDelete(item);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'restore', child: Text(AppLocalizations.of(context)!.restoreStr, style: const TextStyle(color: Colors.green))),""", menu_str)

content = content.replace("""
                _buildSection<InvoiceEntity>(
                  context,
                  AppLocalizations.of(context)!.salesStr,
                  _db.select(_db.invoices).watch().map((list) => list.where((e) => !e.isActive).toList()),
                  (e) => e.id,
                  (e) => '${e.documentType} #${e.invoiceNumber}',
                  (e) async {
                    await ref.read(salesServiceProvider).restoreInvoice(e.id, userId);
                  },
                  (e) async {
                    await (_db.delete(_db.invoices)..where((t) => t.id.equals(e.id))).go();
                  },
                  buildSubtitle: (e) => Text('${AppLocalizations.of(context)!.totalStr}: ${e.total} - ${DateFormat('yyyy-MM-dd').format(e.date)}'),
                ),
""", """
                _buildSection<InvoiceEntity>(
                  context,
                  AppLocalizations.of(context)!.salesStr,
                  _db.select(_db.invoices).watch().map((list) => list.where((e) => !e.isActive).toList()),
                  (e) => e.id,
                  (e) => '${e.documentType} #${e.invoiceNumber}',
                  (e) async {
                    await ref.read(salesServiceProvider).restoreInvoice(e.id, userId);
                  },
                  (e) async {
                    await (_db.delete(_db.invoices)..where((t) => t.id.equals(e.id))).go();
                  },
                  onEdit: (e) async {
                    final client = e.clientId != null ? await (_db.select(_db.clients)..where((t) => t.id.equals(e.clientId!))).getSingleOrNull() : null;
                    await onEditInvoice(e, client, _db);
                  },
                  buildSubtitle: (e) => Text('${AppLocalizations.of(context)!.totalStr}: ${e.total} - ${DateFormat('yyyy-MM-dd').format(e.date)}'),
                ),
""")

content = content.replace("""
                _buildSection<PurchaseEntity>(
                  context,
                  AppLocalizations.of(context)!.purchasesStr,
                  _db.select(_db.purchases).watch().map((list) => list.where((e) => !e.isActive).toList()),
                  (e) => e.id,
                  (e) => '${e.documentType} #${e.purchaseNumber}',
                  (e) async {
                    await ref.read(purchaseServiceProvider).restorePurchase(e.id, userId);
                  },
                  (e) async {
                    await (_db.delete(_db.purchases)..where((t) => t.id.equals(e.id))).go();
                  },
                  buildSubtitle: (e) => Text('${AppLocalizations.of(context)!.totalStr}: ${e.total} - ${DateFormat('yyyy-MM-dd').format(e.date)}'),
                ),
""", """
                _buildSection<PurchaseEntity>(
                  context,
                  AppLocalizations.of(context)!.purchasesStr,
                  _db.select(_db.purchases).watch().map((list) => list.where((e) => !e.isActive).toList()),
                  (e) => e.id,
                  (e) => '${e.documentType} #${e.purchaseNumber}',
                  (e) async {
                    await ref.read(purchaseServiceProvider).restorePurchase(e.id, userId);
                  },
                  (e) async {
                    await (_db.delete(_db.purchases)..where((t) => t.id.equals(e.id))).go();
                  },
                  onEdit: (e) async {
                    final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(e.supplierId))).getSingleOrNull();
                    await onEditPurchase(e, supplier, _db);
                  },
                  buildSubtitle: (e) => Text('${AppLocalizations.of(context)!.totalStr}: ${e.total} - ${DateFormat('yyyy-MM-dd').format(e.date)}'),
                ),
""")

with open('lib/src/presentation/settings/garbage_screen.dart', 'w') as f:
    f.write(content)
