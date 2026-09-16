import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables/products.dart';
import 'tables/clients.dart';
import 'tables/stock.dart';
import 'tables/consumables.dart';
import 'tables/sync.dart';
import 'tables/sales.dart';
import 'tables/sequences.dart';
import 'tables/users.dart';
import 'tables/suppliers.dart';
import 'tables/purchases.dart';
import 'tables/hr.dart';
import 'tables/system.dart';

import '../../utils/decimal_converter.dart';
import 'package:decimal/decimal.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Products,
    ProductRelations, 
  Clients,
  StockLocations,
  StockMovements,
  StockBalances,
  ProductConsumables,
  SyncOutbox,
  Invoices,
  InvoiceLines,
  Payments,
  AuditLogs,
  DocumentSequences,
  Users,
  Suppliers,
  Purchases,
  PurchaseLines,
  Employees,
  PayrollRecords,
  EmployeeActivities,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  AppDatabase.forTesting(super.e);

  Future<void> clearAllData() async {
    await transaction(() async {
      await customStatement('PRAGMA foreign_keys = OFF');
      
      for (final table in allTables) {
        await delete(table).go();
      }
      
      // Re-seed defaults
      await into(stockLocations).insert(StockLocationsCompanion.insert(
        id: 'BASE_WAREHOUSE_01',
        name: 'Main Warehouse',
        type: 'BASE',
      ));
      
      await into(stockLocations).insert(StockLocationsCompanion.insert(
        id: 'MAGAZIN_01',
        name: 'Client Magazin',
        type: 'MAGAZIN',
      ));
      
      await into(clients).insert(ClientsCompanion.insert(
        id: 'WALKIN_CLIENT_01',
        name: 'Client Passager',
        type: const Value('TEMP'),
        tier: const Value('Tier 3'),
      ));
      
      await customStatement('PRAGMA foreign_keys = ON');
    });
  }

  @override
  int get schemaVersion => 18;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // Create initial default BASE stock location
        await into(stockLocations).insert(StockLocationsCompanion.insert(
          id: 'BASE_WAREHOUSE_01',
          name: 'Main Warehouse',
          type: 'BASE',
        ));
        
        // Seed the system walk-in / temporary client
        await into(clients).insert(ClientsCompanion.insert(
          id: 'WALKIN_CLIENT_01',
          name: 'Client Passager',
          type: const Value('TEMP'),
          tier: const Value('Tier 3'),
        ));
      },
onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add new columns for version 2
          await m.addColumn(clients, clients.phone);
          await m.addColumn(clients, clients.email);
          await m.addColumn(clients, clients.imagePath);

          await m.addColumn(suppliers, suppliers.phone);
          await m.addColumn(suppliers, suppliers.email);
          await m.addColumn(suppliers, suppliers.imagePath);

          await m.addColumn(employees, employees.phone);
          await m.addColumn(employees, employees.email);
          await m.addColumn(employees, employees.imagePath);
          await m.addColumn(employees, employees.idScanPath);

          await m.addColumn(products, products.imagePath);
          await m.addColumn(products, products.tier2Price);
          await m.addColumn(products, products.tier3Price);
          await m.addColumn(products, products.packagingType);

          await m.addColumn(invoices, invoices.documentType);
        }
        if (from < 3) {
          await m.addColumn(payments, payments.checkImagePath);
        }
        if (from < 4) {
          await m.createTable(productRelations);
        }
        if (from < 5) {
          await m.addColumn(payments, payments.supplierId);
          await m.addColumn(payments, payments.employeeId);
        }
        if (from < 6) {
          await m.createTable(settings);
          await m.addColumn(employees, employees.role);
          await m.addColumn(employees, employees.pinCode);
        }
        if (from < 7) {
          await m.addColumn(products, products.unitSize);
        }
        if (from < 8) {
          await m.addColumn(products, products.unitsPerBox);
        }
        if (from < 9) {
          await m.addColumn(clients, clients.tier);
        }
        if (from < 10) {
          await m.addColumn(clients, clients.type);
        }
        if (from < 11) {
          await m.addColumn(invoices, invoices.isActive as GeneratedColumn<Object>);
          await m.addColumn(purchases, purchases.isActive as GeneratedColumn<Object>);
          await m.addColumn(payments, payments.isActive as GeneratedColumn<Object>);
        }
        if (from < 12) {
          await m.addColumn(purchases, purchases.documentType as GeneratedColumn<Object>);
        }
        if (from < 13) {
          await into(stockLocations).insert(StockLocationsCompanion.insert(
            id: 'MAGAZIN_01',
            name: 'Client Magazin',
            type: 'MAGAZIN',
          ), mode: InsertMode.insertOrIgnore);
        }
        if (from < 14) {
          await m.addColumn(payments, payments.purchaseId as GeneratedColumn<Object>);
        }
        if (from < 15) {
          await m.addColumn(products, products.baseMinimumStock);
          await m.addColumn(products, products.magazinMinimumStock);
        }
        if (from < 16) {
          await m.alterTable(TableMigration(payments));
        }
        if (from < 17) {
          await m.addColumn(products, products.nameAr);
          await m.addColumn(products, products.nameFr);
          await m.addColumn(products, products.nameEs);
        }
        if (from < 18) {
          // Seed walk-in / temporary client for existing databases
          await into(clients).insert(ClientsCompanion.insert(
            id: 'WALKIN_CLIENT_01',
            name: 'Client Passager',
            type: const Value('TEMP'),
            tier: const Value('Tier 3'),
          ), mode: InsertMode.insertOrIgnore);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        // Force Client Passager to Tier 3 prices always
        await customStatement("UPDATE clients SET tier = 'Tier 3' WHERE id = 'WALKIN_CLIENT_01'");
        // Mathematical Clamping: Erase any ghost negative stock from the engine
        await customStatement("UPDATE stock_balances SET quantity = '0' WHERE CAST(quantity AS REAL) < 0");
        // Cleanup: Remove orphaned stock_balances pointing to deleted products
        await customStatement("DELETE FROM stock_balances WHERE product_id NOT IN (SELECT id FROM products)");
        // Cleanup: Remove zero-quantity noise
        await customStatement("DELETE FROM stock_balances WHERE quantity = '0' OR quantity = '0.0' OR quantity = '0.000000'");
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'markogroup_erp.sqlite'));
    
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;
    
    return NativeDatabase.createInBackground(file);
  });
}
