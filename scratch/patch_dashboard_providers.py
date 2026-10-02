import re

with open('lib/src/application/dashboard/dashboard_providers.dart', 'r') as f:
    content = f.read()

# 1. todaySalesProvider
old_sales = """  // Watch invoices table directly for instant reactivity
  return (db.select(db.invoices)..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.isActive.equals(true))).watch().map((invoices) {"""

new_sales = """  // Watch invoices table directly for instant reactivity
  return (db.select(db.invoices)..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.isActive.equals(true) & t.documentType.isNotIn(['COMMANDE', 'FACTURE', 'FACTURE_DUMMY']))).watch().map((invoices) {"""
content = content.replace(old_sales, new_sales)

# 2. todaysCreditProvider
old_credit = """  // Watch invoices table directly for instant reactivity
  return (db.select(db.invoices)..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.isActive.equals(true))).watch().map((invoices) {"""

new_credit = """  // Watch invoices table directly for instant reactivity
  return (db.select(db.invoices)..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.isActive.equals(true) & t.documentType.isNotIn(['COMMANDE', 'FACTURE', 'FACTURE_DUMMY']))).watch().map((invoices) {"""
content = content.replace(old_credit, new_credit)

# 3. topSellingProductsProvider
old_top_prod = """    final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true) & ((t.clientId.isIn(normalIds) | t.clientId.isNull()) | t.clientId.isNull()))).get();"""

new_top_prod = """    final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true) & t.documentType.isNotIn(['COMMANDE', 'FACTURE', 'FACTURE_DUMMY']) & ((t.clientId.isIn(normalIds) | t.clientId.isNull()) | t.clientId.isNull()))).get();"""
content = content.replace(old_top_prod, new_top_prod)

# 4. salesChartDataProvider
old_chart = """  return (db.select(db.invoices)..where((t) => t.isActive.equals(true))).watch().asyncMap((invoices) async {"""

new_chart = """  return (db.select(db.invoices)..where((t) => t.isActive.equals(true) & t.documentType.isNotIn(['COMMANDE', 'FACTURE', 'FACTURE_DUMMY']))).watch().asyncMap((invoices) async {"""
content = content.replace(old_chart, new_chart)

# 5. remindersProvider (Unpaid Invoices shouldn't include Factures since they don't have debt/payments)
old_reminder = """    final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true))).get();
    for (final inv in invoices.where((i) => i.status == 'UNPAID' || i.status == 'PARTIAL')) {"""
new_reminder = """    final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true) & t.documentType.isNotIn(['COMMANDE', 'FACTURE', 'FACTURE_DUMMY']))).get();
    for (final inv in invoices.where((i) => i.status == 'UNPAID' || i.status == 'PARTIAL')) {"""
content = content.replace(old_reminder, new_reminder)

with open('lib/src/application/dashboard/dashboard_providers.dart', 'w') as f:
    f.write(content)
print("Dashboard providers patched.")
