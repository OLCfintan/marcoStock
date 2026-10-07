import re

with open('lib/src/infrastructure/repositories/product_repository.dart', 'r') as f:
    content = f.read()

# Replace deleteProduct
old_delete = """  Future<void> deleteProduct(String id) async {
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(const ProductsCompanion(isActive: drift.Value(false)));
  }"""

new_delete = """  Future<void> deleteProduct(String id) async {
    final product = await (_db.select(_db.products)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (product != null) {
      await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(ProductsCompanion(
        isActive: const drift.Value(false),
        reference: drift.Value('${product.reference}-DEL-${DateTime.now().millisecondsSinceEpoch}'),
      ));
    }
  }"""

content = content.replace(old_delete, new_delete)

with open('lib/src/infrastructure/repositories/product_repository.dart', 'w') as f:
    f.write(content)
