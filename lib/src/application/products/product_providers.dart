import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/products/product.dart';
import '../../infrastructure/repositories/product_repository.dart';

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchAllProducts();
});
