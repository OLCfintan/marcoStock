import re

with open('lib/src/application/dashboard/dashboard_providers.dart', 'r') as f:
    content = f.read()

old_provider = """final salesChartDataProvider = StreamProvider<List<ChartDataPoint>>((ref) {
  final period = ref.watch(salesChartPeriodProvider);
  final db = ref.watch(databaseProvider);
  
  return db.select(db.clients).watch().asyncMap((clients) async {
    final normalIds = clients.where((c) => c.type == 'NORMAL').map((c) => c.id).toList();
    if (normalIds.isEmpty) return [];
    final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true) & ((t.clientId.isIn(normalIds) | t.clientId.isNull()) | t.clientId.isNull()))).get();
    final now = DateTime.now();
    final data = <String, Decimal>{};
    
    for (final inv in invoices) {
      if (period == SalesChartPeriod.daily) {
        if (inv.date.isAfter(now.subtract(const Duration(days: 7)))) {
          final dayStr = '${inv.date.month}/${inv.date.day}';
          data[dayStr] = (data[dayStr] ?? Decimal.zero) + inv.total;
        }
      } else if (period == SalesChartPeriod.weekly) {
        if (inv.date.isAfter(now.subtract(const Duration(days: 30)))) {
          // Simplistic week grouping
          final weekNum = ((inv.date.day - 1) / 7).floor() + 1;
          final weekStr = 'Week $weekNum, ${inv.date.month}';
          data[weekStr] = (data[weekStr] ?? Decimal.zero) + inv.total;
        }
      } else {
        if (inv.date.isAfter(now.subtract(const Duration(days: 365)))) {
          final monthStr = '${inv.date.year}-${inv.date.month.toString().padLeft(2, '0')}';
          data[monthStr] = (data[monthStr] ?? Decimal.zero) + inv.total;
        }
      }
    }
    
    final sortedKeys = data.keys.toList()..sort();
    return sortedKeys.map((k) => ChartDataPoint(k, data[k]!)).toList();
  });
});"""

new_provider = """import 'dart:collection';

final salesChartDataProvider = StreamProvider<List<ChartDataPoint>>((ref) {
  final period = ref.watch(salesChartPeriodProvider);
  final db = ref.watch(databaseProvider);
  
  return db.select(db.clients).watch().asyncMap((clients) async {
    final normalIds = clients.where((c) => c.type == 'NORMAL').map((c) => c.id).toList();
    if (normalIds.isEmpty) return [];
    final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true) & ((t.clientId.isIn(normalIds) | t.clientId.isNull()) | t.clientId.isNull()))).get();
    final now = DateTime.now();
    
    final data = LinkedHashMap<String, Decimal>();
    
    if (period == SalesChartPeriod.daily) {
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        data['${d.month}/${d.day}'] = Decimal.zero;
      }
    } else if (period == SalesChartPeriod.weekly) {
      for (int i = 4; i >= 0; i--) {
        final d = now.subtract(Duration(days: i * 7));
        final weekNum = ((d.day - 1) / 7).floor() + 1;
        data['Week $weekNum, ${d.month}'] = Decimal.zero;
      }
    } else {
      for (int i = 11; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        data['${d.year}-${d.month.toString().padLeft(2, '0')}'] = Decimal.zero;
      }
    }
    
    for (final inv in invoices) {
      if (period == SalesChartPeriod.daily) {
        if (inv.date.isAfter(now.subtract(const Duration(days: 7)))) {
          final dayStr = '${inv.date.month}/${inv.date.day}';
          if (data.containsKey(dayStr)) {
            data[dayStr] = data[dayStr]! + inv.total;
          }
        }
      } else if (period == SalesChartPeriod.weekly) {
        if (inv.date.isAfter(now.subtract(const Duration(days: 34)))) {
          final weekNum = ((inv.date.day - 1) / 7).floor() + 1;
          final weekStr = 'Week $weekNum, ${inv.date.month}';
          if (data.containsKey(weekStr)) {
            data[weekStr] = data[weekStr]! + inv.total;
          }
        }
      } else {
        if (inv.date.isAfter(now.subtract(const Duration(days: 365)))) {
          final monthStr = '${inv.date.year}-${inv.date.month.toString().padLeft(2, '0')}';
          if (data.containsKey(monthStr)) {
            data[monthStr] = data[monthStr]! + inv.total;
          }
        }
      }
    }
    
    return data.entries.map((e) => ChartDataPoint(e.key, e.value)).toList();
  });
});"""

content = content.replace(old_provider, new_provider)
content = content.replace("import 'dart:collection';\n\nimport 'dart:collection';", "import 'dart:collection';") # just in case

with open('lib/src/application/dashboard/dashboard_providers.dart', 'w') as f:
    f.write(content)
