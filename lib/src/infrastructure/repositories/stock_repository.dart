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
    // Joins StockBalances with Products and Locations
    final query = _db.select(_db.stockBalances).join([
      innerJoin(_db.products, _db.products.id.equalsExp(_db.stockBalances.productId)),
      innerJoin(_db.stockLocations, _db.stockLocations.id.equalsExp(_db.stockBalances.locationId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final balance = row.readTable(_db.stockBalances);
        final product = row.readTable(_db.products);
        final location = row.readTable(_db.stockLocations);

        return StockItem(
          productId: product.id,
          productName: product.name,
          productReference: product.reference,
          unitSize: product.unitSize,
          unit: product.unit,
          locationId: location.id,
          locationName: location.name,
          quantity: balance.quantity,
        );
      }).toList();
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
