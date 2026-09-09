import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../domain/constants/locations.dart';

import '../../infrastructure/database/app_database.dart';

class StockTransferService {
  final AppDatabase _db;
  final String _currentUserId;
  final _uuid = const Uuid();

  StockTransferService(this._db, this._currentUserId);

  Future<void> executeTransfer(
    String productId,
    String fromLocationId,
    String toLocationId,
    Decimal quantity,
  ) async {
    if (quantity <= Decimal.zero) {
      throw ArgumentError('Quantity must be greater than zero');
    }

    if (fromLocationId == toLocationId) {
      throw ArgumentError('Source and destination locations cannot be the same');
    }

    await _db.transaction(() async {
      // Resolve product Family Base Unit and scale quantity
      final product = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingle();
      
      String targetProductId = product.id;
      final unitSize = product.unitSize;
      
      if (product.unitSize != Decimal.one) {
        final familyProducts = await (_db.select(_db.products)..where((t) => t.name.equals(product.name))).get();
        // Prefer the exact product mathematically defined as the base (unitSize == 1)
        final baseProduct = familyProducts.firstWhere(
          (p) => p.unitSize == Decimal.one,
          orElse: () => familyProducts.firstWhere(
            (p) => p.packagingType == 'Unit' || p.packagingType == null || p.packagingType == '',
            orElse: () => product,
          ),
        );
        targetProductId = baseProduct.id;
      }
      
      final totalBaseUnits = quantity * unitSize;

      // 1. Deduct from source
      final sourceBalance = await (_db.select(_db.stockBalances)
            ..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(fromLocationId)))
          .getSingleOrNull();

      if (sourceBalance == null || sourceBalance.quantity < totalBaseUnits) {
        throw Exception('Insufficient stock at source location for base unit');
      }

      await _db.update(_db.stockBalances).replace(
            sourceBalance.copyWith(
              quantity: sourceBalance.quantity - totalBaseUnits,
              updatedAt: DateTime.now(),
            ),
          );

      // 2. Add to destination
      final destBalance = await (_db.select(_db.stockBalances)
            ..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(toLocationId)))
          .getSingleOrNull();

      if (destBalance == null) {
        await _db.into(_db.stockBalances).insert(
              StockBalancesCompanion.insert(
                productId: targetProductId,
                locationId: toLocationId,
                quantity: totalBaseUnits,
              ),
            );
      } else {
        await _db.update(_db.stockBalances).replace(
              destBalance.copyWith(
                quantity: destBalance.quantity + totalBaseUnits,
                updatedAt: DateTime.now(),
              ),
            );
      }

      // 3. Create StockMovement record
      await _db.into(_db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: _uuid.v4(),
              productId: targetProductId,
              sourceLocationId: Value(fromLocationId),
              targetLocationId: Value(toLocationId),
              quantity: totalBaseUnits,
              reason: 'TRANSFER',
              createdBy: _currentUserId,
            ),
          );
    });
  }
}
