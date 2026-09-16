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
  
  return (db.select(db.invoices)
        ..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.isActive.equals(true)))
      .watch()
      .map((sales) => sales.fold<Decimal>(Decimal.zero, (sum, inv) => sum + inv.total));
});

// --- Outstanding Debt ---
final outstandingDebtProvider = StreamProvider<Decimal>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.clients)..where((t) => t.isActive.equals(true))).watch().map((clients) => 
    clients.fold<Decimal>(Decimal.zero, (sum, c) => sum + (c.balance > Decimal.zero ? c.balance : Decimal.zero))
  );
});

// --- Profit Margin ---
final profitMarginProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.invoices)..where((t) => t.isActive.equals(true))).watch().asyncMap((invoices) async {
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
});

// --- Top Selling Products ---
final topSellingProductsProvider = StreamProvider<List<TopProduct>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.invoices)..where((t) => t.isActive.equals(true))).watch().asyncMap((invoices) async {
    final activeInvoiceIds = invoices.map((i) => i.id).toList();
    final map = <String, TopProduct>{};
    if (activeInvoiceIds.isEmpty) return [];
    
    final lines = await (db.select(db.invoiceLines)..where((t) => t.invoiceId.isIn(activeInvoiceIds))).get();
    for (final line in lines) {
      final product = await (db.select(db.products)..where((t) => t.id.equals(line.productId))).getSingleOrNull();
      if (product == null) continue;
      final current = map[product.id] ?? TopProduct(product.name, Decimal.zero, Decimal.zero);
      map[product.id] = TopProduct(
        product.name,
        current.totalRevenue + line.lineTotal,
        current.totalQuantity + line.quantity,
      );
    }
    
    final list = map.values.toList();
    list.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
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
      
      // 2. Extract highest minimums for this entire family
      Decimal familyBaseMin = Decimal.zero;
      Decimal familyMagazinMin = Decimal.zero;
      
      for (final p in family) {
        final pBaseMin = p.baseMinimumStock > Decimal.zero ? p.baseMinimumStock : p.minimumStock;
        if (pBaseMin > familyBaseMin) familyBaseMin = pBaseMin;
        
        final pMagMin = p.magazinMinimumStock > Decimal.zero ? p.magazinMinimumStock : p.minimumStock;
        if (pMagMin > familyMagazinMin) familyMagazinMin = pMagMin;
      }
      
      // Since ALL stock (Base & Magazin) is routed to the rootProduct mathematically, we evaluate ONCE per family
      
      // A. Evaluate Base Stock
      if (familyBaseMin > Decimal.zero) {
        final baseQuery = db.select(db.stockBalances)..where((t) => t.productId.equals(rootProduct.id) & t.locationId.equals(AppLocations.baseWarehouse));
        final baseBalances = await baseQuery.get();
        final baseTotal = baseBalances.fold(Decimal.zero, (sum, b) => sum + b.quantity);
        
        if (baseTotal <= familyBaseMin) {
          final baseLabel = ' ${rootProduct.unitSize}${rootProduct.unit}';
          alerts.add(LowStockAlert('${rootProduct.name}$baseLabel (Base)', baseTotal, familyBaseMin));
        }
      }

      // B. Evaluate Magazin Stock
      if (familyMagazinMin > Decimal.zero) {
        final magazinQuery = db.select(db.stockBalances)..where((t) => t.productId.equals(rootProduct.id) & t.locationId.equals(AppLocations.magazin));
        final magazinBalances = await magazinQuery.get();
        final magazinTotal = magazinBalances.fold(Decimal.zero, (sum, b) => sum + b.quantity);
        
        if (magazinTotal <= familyMagazinMin) {
          final baseLabel = ' ${rootProduct.unitSize}${rootProduct.unit}';
          alerts.add(LowStockAlert('${rootProduct.name}$baseLabel (Magazin)', magazinTotal, familyMagazinMin));
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
  
  return (db.select(db.invoices)..where((t) => t.isActive.equals(true))).watch().map((invoices) {
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
});

// --- Top Clients ---
final topClientsProvider = StreamProvider<List<TopHuman>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.clients)..where((t) => t.isActive.equals(true))).watch().map((clients) {
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
