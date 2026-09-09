import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/repositories/supplier_repository.dart';

final suppliersStreamProvider = StreamProvider<List<Supplier>>((ref) {
  final repo = ref.watch(supplierRepositoryProvider);
  return repo.watchAllSuppliers();
});
