import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/providers.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository(ref.watch(databaseProvider));
});

class StockItem {
  final String productId;
  final String productName;
  final String productReference;
  final Decimal unitSize;
  final String unit;
  final String locationId;
  final String locationName;
  final Decimal quantity;

  StockItem({
    required this.productId,
    required this.productName,
    required this.productReference,
    required this.unitSize,
    required this.unit,
    required this.locationId,
    required this.locationName,
    required this.quantity,
  });
}

class StockRepository {
  final AppDatabase _db;

  StockRepository(this._db);

  Stream<List<StockItem>> watchStockBalances() {
    // Watch stock_balances table for changes
    return _db.select(_db.stockBalances).watch().asyncMap((balances) async {
      final items = <StockItem>[];
      for (final balance in balances) {
        // if (balance.quantity <= Decimal.zero) continue; // Allow viewing zero and negative stocks for auditing
        
        final product = await (_db.select(_db.products)
          ..where((t) => t.id.equals(balance.productId)))
          .getSingleOrNull();
        if (product == null) continue; // Skip orphaned stock
        
        final location = await (_db.select(_db.stockLocations)
          ..where((t) => t.id.equals(balance.locationId)))
          .getSingleOrNull();
        if (location == null) continue;
        
        items.add(StockItem(
          productId: product.id,
          productName: product.name,
          productReference: product.reference,
          unitSize: product.unitSize,
          unit: product.unit,
          locationId: location.id,
          locationName: location.name,
          quantity: balance.quantity,
        ));
      }
      return items;
    });
  }

  Stream<List<StockLocationEntity>> watchLocations() {
    return _db.select(_db.stockLocations).watch();
  }

  Future<void> deleteStock(String productId, String locationId) async {
    await (_db.delete(_db.stockBalances)
      ..where((t) => t.productId.equals(productId) & t.locationId.equals(locationId)))
      .go();
  }
}
