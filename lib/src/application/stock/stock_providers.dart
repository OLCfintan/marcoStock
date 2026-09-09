import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/repositories/stock_repository.dart';
import '../../infrastructure/database/providers.dart';
import '../../infrastructure/database/app_database.dart';
import '../auth/auth_service.dart';
import 'stock_transfer_service.dart';

final stockBalancesStreamProvider = StreamProvider<List<StockItem>>((ref) {
  final repo = ref.watch(stockRepositoryProvider);
  return repo.watchStockBalances();
});

final stockLocationsStreamProvider = StreamProvider<List<StockLocationEntity>>((ref) {
  final repo = ref.watch(stockRepositoryProvider);
  return repo.watchLocations();
});

final stockTransferServiceProvider = Provider<StockTransferService?>((ref) {
  final db = ref.watch(databaseProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return StockTransferService(db, user.id);
});
