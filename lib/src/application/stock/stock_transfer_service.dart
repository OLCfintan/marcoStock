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
      final product = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingle();
      
      // Determine tracking parameters based on source/dest rules
      final sourceInfo = await getStockTrackingInfo(_db, product, quantity, fromLocationId);
      final destInfo = await getStockTrackingInfo(_db, product, quantity, toLocationId);

      // 1. Deduct from source
      final sourceBalance = await (_db.select(_db.stockBalances)
            ..where((t) => t.productId.equals(sourceInfo.productId) & t.locationId.equals(fromLocationId)))
          .getSingleOrNull();

      final currentQty = sourceBalance?.quantity ?? Decimal.zero;
      if (currentQty < sourceInfo.quantity) {
        throw Exception('Insufficient stock at source location for transfer. Available: ${currentQty.toStringAsFixed(2)}, Requested: ${sourceInfo.quantity.toStringAsFixed(2)}');
      }

      if (sourceBalance == null) {
        await _db.into(_db.stockBalances).insert(StockBalancesCompanion.insert(
              productId: sourceInfo.productId,
              locationId: fromLocationId,
              quantity: -sourceInfo.quantity,
            ));
      } else {
        await _db.update(_db.stockBalances).replace(
              sourceBalance.copyWith(
                quantity: sourceBalance.quantity - sourceInfo.quantity,
                updatedAt: DateTime.now(),
              ),
            );
      }

      // 2. Add to destination
      final destBalance = await (_db.select(_db.stockBalances)
            ..where((t) => t.productId.equals(destInfo.productId) & t.locationId.equals(toLocationId)))
          .getSingleOrNull();

      if (destBalance == null) {
        await _db.into(_db.stockBalances).insert(
              StockBalancesCompanion.insert(
                productId: destInfo.productId,
                locationId: toLocationId,
                quantity: destInfo.quantity,
              ),
            );
      } else {
        await _db.update(_db.stockBalances).replace(
              destBalance.copyWith(
                quantity: destBalance.quantity + destInfo.quantity,
                updatedAt: DateTime.now(),
              ),
            );
      }

      // 3. Create StockMovement record (record the physical unit movement)
      await _db.into(_db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: _uuid.v4(),
              productId: product.id, // Record the exact physical product moved
              sourceLocationId: Value(fromLocationId),
              targetLocationId: Value(toLocationId),
              quantity: quantity, // Record the raw physical quantity
              reason: 'TRANSFER',
              createdBy: _currentUserId,
            ),
          );
    });
  }
}
