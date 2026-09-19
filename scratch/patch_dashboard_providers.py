import re

with open('lib/src/application/dashboard/dashboard_providers.dart', 'r') as f:
    content = f.read()

# Replace profitMarginProvider with todaysCreditProvider
old_profit_code = """// --- Profit Margin ---
final profitMarginProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.clients).watch().asyncMap((clients) async {
    final normalIds = clients.where((c) => c.type == 'NORMAL').map((c) => c.id).toList();
    if (normalIds.isEmpty) return 0.0;
    final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true) & t.clientId.isIn(normalIds))).get();
    Decimal totalRevenue = Decimal.zero;
    Decimal totalCost = Decimal.zero;
    final activeInvoiceIds = invoices.map((i) => i.id).toList();
    if (activeInvoiceIds.isEmpty) return 0.0;
    
    final lines = await (db.select(db.invoiceLines)..where((t) => t.invoiceId.isIn(activeInvoiceIds))).get();
    
    for (final line in lines) {
      final product = await (db.select(db.products)..where((t) => t.id.equals(line.productId))).getSingleOrNull();
      if (product == null) continue;
      
      // Since stock deducts base units, the line.quantity is base units (from our previous fix).
      // product.purchasePrice is the cost per base unit.
      final cost = line.quantity * product.purchasePrice;
      
      totalRevenue += line.lineTotal;
      totalCost += cost;
    }
    
    if (totalRevenue <= Decimal.zero) return 0.0;
    
    final profit = totalRevenue - totalCost;
    final margin = double.parse(profit.toString()) / double.parse(totalRevenue.toString());
    return margin * 100.0; // Return as percentage
  });
});"""

new_credit_code = """// --- Today's Credit ---
final todaysCreditProvider = StreamProvider<Decimal>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  
  return db.select(db.clients).watch().asyncMap((clients) async {
    final normalIds = clients.where((c) => c.type == 'NORMAL').map((c) => c.id).toList();
    if (normalIds.isEmpty) return Decimal.zero;
    final invoices = await (db.select(db.invoices)..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.isActive.equals(true) & t.clientId.isIn(normalIds))).get();
    return invoices.fold<Decimal>(Decimal.zero, (sum, inv) => sum + (inv.total - inv.paidAmount));
  });
});"""

content = content.replace(old_profit_code, new_credit_code)

with open('lib/src/application/dashboard/dashboard_providers.dart', 'w') as f:
    f.write(content)

