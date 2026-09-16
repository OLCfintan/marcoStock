import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../infrastructure/database/app_database.dart';
import 'stock_helpers.dart';

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
      
      final baseProduct = await getDeterministicBaseProduct(_db, product);
      String targetProductId = baseProduct.id;
      
      final totalBaseUnits = convertQuantityToBase(quantity, product, baseProduct);

      // 1. Deduct from source
      final sourceBalance = await (_db.select(_db.stockBalances)
            ..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(fromLocationId)))
          .getSingleOrNull();

      // Mathematically preserve balances
      final actualTransfer = totalBaseUnits;

      if (sourceBalance == null) {
        await _db.into(_db.stockBalances).insert(StockBalancesCompanion.insert(
              productId: targetProductId,
              locationId: fromLocationId,
              quantity: -actualTransfer,
            ));
      } else {
        await _db.update(_db.stockBalances).replace(
              sourceBalance.copyWith(
                quantity: sourceBalance.quantity - actualTransfer,
                updatedAt: DateTime.now(),
              ),
            );
      }

      // 2. Add to destination
      final destBalance = await (_db.select(_db.stockBalances)
            ..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(toLocationId)))
          .getSingleOrNull();

      if (destBalance == null) {
        await _db.into(_db.stockBalances).insert(
              StockBalancesCompanion.insert(
                productId: targetProductId,
                locationId: toLocationId,
                quantity: actualTransfer,
              ),
            );
      } else {
        await _db.update(_db.stockBalances).replace(
              destBalance.copyWith(
                quantity: destBalance.quantity + actualTransfer,
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
              quantity: actualTransfer,
              reason: 'TRANSFER',
              createdBy: _currentUserId,
            ),
          );
    });
  }
}
