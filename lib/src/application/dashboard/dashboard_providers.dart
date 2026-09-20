import 'dart:collection';
import "package:drift/drift.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/constants/locations.dart';
import '../stock/stock_helpers.dart';
import 'package:decimal/decimal.dart';
import '../../infrastructure/database/providers.dart';
import '../../infrastructure/database/app_database.dart';

// --- existing classes ---
class TopProduct {
  final String productName;
  final Decimal totalRevenue;
  final Decimal totalQuantity;

  TopProduct(this.productName, this.totalRevenue, this.totalQuantity);
}

class TopHuman {
  final String name;
  final Decimal balance;

  TopHuman(this.name, this.balance);
}

class LowStockAlert {
  final String productName;
  final Decimal currentStock;
  final Decimal minimumStock;

  LowStockAlert(this.productName, this.currentStock, this.minimumStock);
}

class EmployeePerformance {
  final String employeeName;
  final double score; 
  EmployeePerformance(this.employeeName, this.score);
}

enum SalesChartPeriod { daily, weekly, monthly }

class ChartDataPoint {
  final String label;
  final Decimal value;
  ChartDataPoint(this.label, this.value);
}

final salesChartPeriodProvider = StateProvider<SalesChartPeriod>((ref) => SalesChartPeriod.daily);


// --- Today's Sales ---
final todaySalesProvider = StreamProvider<Decimal>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  
  return db.select(db.clients).watch().asyncMap((clients) async {
    final normalIds = clients.where((c) => c.type == 'NORMAL').map((c) => c.id).toList();
    if (normalIds.isEmpty) return Decimal.zero;
    final invoices = await (db.select(db.invoices)..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.isActive.equals(true) & ((t.clientId.isIn(normalIds) | t.clientId.isNull()) | t.clientId.isNull()))).get();
    return invoices.fold<Decimal>(Decimal.zero, (sum, inv) => sum + inv.total);
  });
});

// --- Outstanding Debt ---
final outstandingDebtProvider = StreamProvider<Decimal>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.clients)..where((t) => t.isActive.equals(true) & t.type.equals('NORMAL'))).watch().map((clients) => 
    clients.fold<Decimal>(Decimal.zero, (sum, c) => sum + (c.balance > Decimal.zero ? c.balance : Decimal.zero))
  );
});

// --- Today's Credit ---
final todaysCreditProvider = StreamProvider<Decimal>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  
  return db.select(db.clients).watch().asyncMap((clients) async {
    final normalIds = clients.where((c) => c.type == 'NORMAL').map((c) => c.id).toList();
    if (normalIds.isEmpty) return Decimal.zero;
    final invoices = await (db.select(db.invoices)..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.isActive.equals(true) & ((t.clientId.isIn(normalIds) | t.clientId.isNull()) | t.clientId.isNull()))).get();
    return invoices.fold<Decimal>(Decimal.zero, (sum, inv) => sum + (inv.total - inv.paidAmount));
  });
});

// --- Top Selling Products ---
final topSellingProductsProvider = StreamProvider<List<TopProduct>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.clients).watch().asyncMap((clients) async {
    final normalIds = clients.where((c) => c.type == 'NORMAL').map((c) => c.id).toList();
    if (normalIds.isEmpty) return [];
    final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true) & ((t.clientId.isIn(normalIds) | t.clientId.isNull()) | t.clientId.isNull()))).get();
    final activeInvoiceIds = invoices.map((i) => i.id).toList();
    final map = <String, TopProduct>{};
    if (activeInvoiceIds.isEmpty) return [];
    
    final lines = await (db.select(db.invoiceLines)..where((t) => t.invoiceId.isIn(activeInvoiceIds))).get();
    for (final line in lines) {
      final product = await (db.select(db.products)..where((t) => t.id.equals(line.productId))).getSingleOrNull();
      if (product == null) continue;
      final baseLabel = product.unitSize == Decimal.one ? ' ${product.unit}' : ' ${product.unitSize}${product.unit}';
      final label = '${product.name}$baseLabel';
      final current = map[product.id] ?? TopProduct(label, Decimal.zero, Decimal.zero);
      map[product.id] = TopProduct(
        label,
        current.totalRevenue + line.lineTotal,
        current.totalQuantity + line.quantity,
      );
    }
    
    final list = map.values.toList();
    list.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    return list.take(5).toList();
  });
});

class TopPayer {
  final String name;
  final Decimal totalPaid;
  TopPayer(this.name, this.totalPaid);
}

final topClientsByRevenueProvider = StreamProvider<List<TopPayer>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.clients).watch().asyncMap((clients) async {
    final list = <TopPayer>[];
    for (final c in clients) {
      if (!c.isActive || c.type != 'NORMAL') continue;
      final payments = await (db.select(db.payments)..where((t) => t.clientId.equals(c.id) & t.isActive.equals(true))).get();
      final total = payments.fold(Decimal.zero, (sum, p) => sum + p.amount);
      if (total > Decimal.zero) {
        list.add(TopPayer(c.name, total));
      }
    }
    list.sort((a, b) => b.totalPaid.compareTo(a.totalPaid));
    return list.take(5).toList();
  });
});

final topSuppliersByRevenueProvider = StreamProvider<List<TopPayer>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.suppliers).watch().asyncMap((suppliers) async {
    final list = <TopPayer>[];
    for (final s in suppliers) {
      if (!s.isActive) continue;
      final payments = await (db.select(db.payments)..where((t) => t.supplierId.equals(s.id) & t.isActive.equals(true))).get();
      final total = payments.fold(Decimal.zero, (sum, p) => sum + p.amount);
      if (total > Decimal.zero) {
        list.add(TopPayer(s.name, total));
      }
    }
    list.sort((a, b) => b.totalPaid.compareTo(a.totalPaid));
    return list.take(5).toList();
  });
});

// --- Low Stock Alerts ---
final lowStockAlertsProvider = StreamProvider<List<LowStockAlert>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.customSelect('SELECT 1', readsFrom: {db.products, db.stockBalances}).watch().asyncMap((_) async {
    final products = await (db.select(db.products)..where((t) => t.isActive.equals(true))).get();
    final alerts = <LowStockAlert>[];
    
    // Group products by family name dynamically
    final familyGroups = <String, List<ProductEntity>>{};
    for (final p in products) {
      // We no longer filter by packagingType, we want to evaluate EVERY active product!
      familyGroups.putIfAbsent(extractFamilyName(p.name), () => []).add(p);
    }

    for (final familyName in familyGroups.keys) {
      final family = familyGroups[familyName]!;
      
      // 1. Determine Exact Mathematical Root Product to sync with Stock Engine
      final rootProduct = await getDeterministicBaseProduct(db, family.first);
      
      // 2. Extract highest minimums for this entire family dynamically converted to SI Units
      Decimal familyBaseMinInSI = Decimal.zero;
      
      for (final p in family) {
        final pBaseMin = p.baseMinimumStock > Decimal.zero ? p.baseMinimumStock : p.minimumStock;
        if (pBaseMin > Decimal.zero) {
          final pBaseMinSI = convertQuantityToBase(pBaseMin, p, rootProduct);
          if (pBaseMinSI > familyBaseMinInSI) familyBaseMinInSI = pBaseMinSI;
        }

        // 3. Evaluate Magazin Stock INDIVIDUALLY for each variant (because Magazin tracks physical variants directly)
        final pMagMin = p.magazinMinimumStock > Decimal.zero ? p.magazinMinimumStock : p.minimumStock;
        if (pMagMin > Decimal.zero) {
          final magazinQuery = db.select(db.stockBalances)..where((t) => t.productId.equals(p.id) & t.locationId.equals(AppLocations.magazin));
          final magazinBalances = await magazinQuery.get();
          final magazinTotal = magazinBalances.fold(Decimal.zero, (sum, b) => sum + b.quantity);
          
          if (magazinTotal <= pMagMin) {
            final baseLabel = p.unitSize == Decimal.one ? ' ${p.unit}' : ' ${p.unitSize}${p.unit}';
            alerts.add(LowStockAlert('${p.name}$baseLabel (Mag)', magazinTotal, pMagMin));
          }
        }
      }
      
      // A. Evaluate Base Stock (Aggregated at the family root)
      if (familyBaseMinInSI > Decimal.zero) {
        final baseQuery = db.select(db.stockBalances)..where((t) => t.productId.equals(rootProduct.id) & t.locationId.equals(AppLocations.baseWarehouse));
        final baseBalances = await baseQuery.get();
        final baseTotal = baseBalances.fold(Decimal.zero, (sum, b) => sum + b.quantity);
        
        if (baseTotal <= familyBaseMinInSI) {
          final baseLabel = rootProduct.unitSize == Decimal.one ? ' ${rootProduct.unit}' : ' ${rootProduct.unitSize}${rootProduct.unit}';
          alerts.add(LowStockAlert('${rootProduct.name}$baseLabel (Base)', baseTotal, familyBaseMinInSI));
        }
      }
    }
    return alerts;
  });
});

// --- Employee Performance ---
final employeePerformanceProvider = StreamProvider<List<EmployeePerformance>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.employees).watch().asyncMap((employees) async {
    final list = <EmployeePerformance>[];
    for (final e in employees) {
      if (!e.isActive) continue;
      final logs = await (db.select(db.auditLogs)..where((t) => t.userId.equals(e.id) & t.action.equals('CREATE_INVOICE'))).get();
      // Cap at 5.0 for UI display logic (e.g. 1 point per 10 invoices)
      double score = logs.length / 10.0;
      if (score > 5.0) score = 5.0;
      list.add(EmployeePerformance(e.name, score));
    }
    return list;
  });
});

// --- Sales Chart ---
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
});

// --- Top Clients ---
final topClientsProvider = StreamProvider<List<TopHuman>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.clients)..where((t) => t.isActive.equals(true) & t.type.equals('NORMAL'))).watch().map((clients) {
    final list = clients.map((c) => TopHuman(c.name, c.balance)).toList();
    list.sort((a, b) => b.balance.compareTo(a.balance));
    return list.take(5).toList();
  });
});

// --- Top Suppliers ---
final topSuppliersProvider = StreamProvider<List<TopHuman>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.suppliers)..where((t) => t.isActive.equals(true))).watch().map((suppliers) {
    final list = suppliers.map((c) => TopHuman(c.name, c.balance)).toList();
    list.sort((a, b) => b.balance.compareTo(a.balance));
    return list.take(5).toList();
  });
});


class ReminderInfo {
  final String title;
  final String subtitle;
  final Decimal amount;
  final String type; // 'CHECK', 'UNPAID_INVOICE'
  ReminderInfo(this.title, this.subtitle, this.amount, this.type);
}

final remindersProvider = StreamProvider<List<ReminderInfo>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.payments)..where((t) => t.isActive.equals(true))).watch().asyncMap((payments) async {
    final reminders = <ReminderInfo>[];
    
    // Checks that are PENDING
    for (final p in payments.where((p) => p.method == 'CHECK' && p.status == 'PENDING')) {
      reminders.add(ReminderInfo('Pending Check', 'Date: ${p.date.toString().split(' ')[0]}', p.amount, 'CHECK'));
    }
    
    // Unpaid Invoices
    final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true))).get();
    for (final inv in invoices.where((i) => i.status == 'UNPAID' || i.status == 'PARTIAL')) {
      final diff = DateTime.now().difference(inv.date).inDays;
      if (diff > 7) { // Due more than 7 days
         reminders.add(ReminderInfo('Overdue Invoice', 'Age: $diff days', inv.total, 'UNPAID_INVOICE'));
      }
    }
    
    return reminders;
  });
});

// --- Stock Distribution (Base vs Magazin) ---
class StockChartData {
  final String label;
  final double value;
  StockChartData(this.label, this.value);
}

final baseStockPieProvider = StreamProvider<List<StockChartData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.customSelect('SELECT 1', readsFrom: {db.products, db.stockBalances}).watch().asyncMap((_) async {
    final balances = await (db.select(db.stockBalances)..where((t) => t.locationId.equals(AppLocations.baseWarehouse))).get();
    
    final map = <String, double>{};
    for (final b in balances) {
      if (b.quantity <= Decimal.zero) continue;
      final product = await (db.select(db.products)..where((t) => t.id.equals(b.productId))).getSingleOrNull();
      if (product == null) continue;
      
      final family = extractFamilyName(product.name);
      // Value = quantity * purchasePrice
      final val = double.parse(b.quantity.toString()) * 1.0;
      map[family] = (map[family] ?? 0.0) + val;
    }
    
    return map.entries.map((e) => StockChartData(e.key, e.value)).toList();
  });
});

final magazinStockPieProvider = StreamProvider<List<StockChartData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.customSelect('SELECT 1', readsFrom: {db.products, db.stockBalances}).watch().asyncMap((_) async {
    final balances = await (db.select(db.stockBalances)..where((t) => t.locationId.equals(AppLocations.magazin))).get();
    
    final map = <String, double>{};
    for (final b in balances) {
      if (b.quantity <= Decimal.zero) continue;
      final product = await (db.select(db.products)..where((t) => t.id.equals(b.productId))).getSingleOrNull();
      if (product == null) continue;
      
      final family = extractFamilyName(product.name);
      // Value = quantity * purchasePrice
      final val = double.parse(b.quantity.toString()) * 1.0;
      map[family] = (map[family] ?? 0.0) + val;
    }
    
    return map.entries.map((e) => StockChartData(e.key, e.value)).toList();
  });
});
