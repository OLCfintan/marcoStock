import re

with open('lib/src/application/dashboard/dashboard_providers.dart', 'r') as f:
    content = f.read()

# 1. Today's Sales
content = re.sub(
    r"""return \(db\.select\(db\.invoices\)\n\s*\.\.where\(\(t\) => t\.date\.isBiggerOrEqualValue\(startOfDay\) & t\.isActive\.equals\(true\)\)\)\n\s*\.watch\(\)\n\s*\.map\(\(sales\) => sales\.fold<Decimal>\(Decimal\.zero, \(sum, inv\) => sum \+ inv\.total\)\);""",
    """return db.select(db.clients).watch().asyncMap((clients) async {
    final normalIds = clients.where((c) => c.type == 'NORMAL').map((c) => c.id).toList();
    if (normalIds.isEmpty) return Decimal.zero;
    final invoices = await (db.select(db.invoices)..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.isActive.equals(true) & t.clientId.isIn(normalIds))).get();
    return invoices.fold<Decimal>(Decimal.zero, (sum, inv) => sum + inv.total);
  });""",
    content
)

# 2. Outstanding Debt
content = content.replace(
    """return (db.select(db.clients)..where((t) => t.isActive.equals(true))).watch().map((clients) =>""",
    """return (db.select(db.clients)..where((t) => t.isActive.equals(true) & t.type.equals('NORMAL'))).watch().map((clients) =>"""
)

# 3. Profit Margin
content = content.replace(
    """return (db.select(db.invoices)..where((t) => t.isActive.equals(true))).watch().asyncMap((invoices) async {""",
    """return db.select(db.clients).watch().asyncMap((clients) async {
    final normalIds = clients.where((c) => c.type == 'NORMAL').map((c) => c.id).toList();
    if (normalIds.isEmpty) return 0.0;
    final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true) & t.clientId.isIn(normalIds))).get();"""
)

# 4. Top Selling Products
content = content.replace(
    """final topSellingProductsProvider = StreamProvider<List<TopProduct>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.invoices)..where((t) => t.isActive.equals(true))).watch().asyncMap((invoices) async {""",
    """final topSellingProductsProvider = StreamProvider<List<TopProduct>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.clients).watch().asyncMap((clients) async {
    final normalIds = clients.where((c) => c.type == 'NORMAL').map((c) => c.id).toList();
    if (normalIds.isEmpty) return [];
    final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true) & t.clientId.isIn(normalIds))).get();"""
)

# 5. Sales Chart
content = content.replace(
    """return (db.select(db.invoices)..where((t) => t.isActive.equals(true))).watch().map((invoices) {""",
    """return db.select(db.clients).watch().asyncMap((clients) async {
    final normalIds = clients.where((c) => c.type == 'NORMAL').map((c) => c.id).toList();
    if (normalIds.isEmpty) return [];
    final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true) & t.clientId.isIn(normalIds))).get();"""
)

# 6. Top Clients
content = re.sub(
    r"""final topClientsProvider = StreamProvider<List<TopHuman>>\(\(ref\) \{\n\s*final db = ref\.watch\(databaseProvider\);\n\s*return \(db\.select\(db\.clients\)\.\.where\(\(t\) => t\.isActive\.equals\(true\)\)\)\.watch\(\)\.map\(\(clients\) \{""",
    """final topClientsProvider = StreamProvider<List<TopHuman>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.clients)..where((t) => t.isActive.equals(true) & t.type.equals('NORMAL'))).watch().map((clients) {""",
    content
)


with open('lib/src/application/dashboard/dashboard_providers.dart', 'w') as f:
    f.write(content)
