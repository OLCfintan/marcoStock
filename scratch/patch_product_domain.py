import re

with open('lib/src/domain/products/product.dart', 'r') as f:
    content = f.read()

# Add displayOrder to Product model
old_props = """  final bool isActive;"""
new_props = """  final bool isActive;
  final int displayOrder;"""
content = content.replace(old_props, new_props)

old_constructor = """    this.isActive = true,
  });"""
new_constructor = """    this.isActive = true,
    this.displayOrder = 0,
  });"""
content = content.replace(old_constructor, new_constructor)

old_copy = """      isActive: isActive ?? this.isActive,
    );"""
new_copy = """      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
    );"""
content = content.replace("      isActive: isActive ?? this.isActive,\n    );", new_copy)
content = content.replace("bool? isActive,", "bool? isActive,\n    int? displayOrder,")


with open('lib/src/domain/products/product.dart', 'w') as f:
    f.write(content)

with open('lib/src/infrastructure/repositories/product_repository.dart', 'r') as f:
    content = f.read()

old_map = """      isActive: e.isActive,
    );"""
new_map = """      isActive: e.isActive,
      displayOrder: e.displayOrder,
    );"""
content = content.replace(old_map, new_map)

old_comp = """      isActive: Value(product.isActive),
    );"""
new_comp = """      isActive: Value(product.isActive),
      displayOrder: Value(product.displayOrder),
    );"""
content = content.replace(old_comp, new_comp)

# Add sorting to watchAllProducts
old_watch = """    return (_db.select(_db.products)..where((t) => t.isActive.equals(true))).watch().map((entities) => entities.map(_mapToDomain).toList());"""
new_watch = """    return (_db.select(_db.products)..where((t) => t.isActive.equals(true))..orderBy([(t) => OrderingTerm(expression: t.displayOrder)])).watch().map((entities) => entities.map(_mapToDomain).toList());"""
content = content.replace(old_watch, new_watch)

# Add sorting to getAllProducts
old_get = """    final entities = await (_db.select(_db.products)..where((t) => t.isActive.equals(true))).get();"""
new_get = """    final entities = await (_db.select(_db.products)..where((t) => t.isActive.equals(true))..orderBy([(t) => OrderingTerm(expression: t.displayOrder)])).get();"""
content = content.replace(old_get, new_get)

# Add reorder method
reorder_method = """  Future<void> updateProductReorder(List<Product> products) async {
    await _db.transaction(() async {
      for (int i = 0; i < products.length; i++) {
        await (_db.update(_db.products)..where((t) => t.id.equals(products[i].id))).write(ProductsCompanion(displayOrder: Value(i)));
      }
    });
  }
"""

content = content.replace("  Stream<List<Product>> watchAllProducts()", reorder_method + "\n  Stream<List<Product>> watchAllProducts()")

with open('lib/src/infrastructure/repositories/product_repository.dart', 'w') as f:
    f.write(content)
