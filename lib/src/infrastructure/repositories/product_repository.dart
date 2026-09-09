import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/products/product.dart';
import '../database/app_database.dart';
import '../database/providers.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(databaseProvider));
});

class ProductRepository {
  final AppDatabase _db;

  ProductRepository(this._db);

  Product _mapToDomain(ProductEntity entity) {
    return Product(
      id: entity.id,
      name: entity.name,
      nameAr: entity.nameAr,
      nameFr: entity.nameFr,
      nameEs: entity.nameEs,
      reference: entity.reference,
      category: entity.category,
      unit: entity.unit,
      unitSize: entity.unitSize,
      unitsPerBox: entity.unitsPerBox,
      purchasePrice: entity.purchasePrice,
      sellingPrice: entity.sellingPrice,
      tier2Price: entity.tier2Price,
      tier3Price: entity.tier3Price,
      minimumStock: entity.minimumStock,
      baseMinimumStock: entity.baseMinimumStock,
      magazinMinimumStock: entity.magazinMinimumStock,
      description: entity.description,
      imagePath: entity.imagePath,
      packagingType: entity.packagingType,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ProductsCompanion _mapToCompanion(Product product) {
    return ProductsCompanion.insert(
      id: product.id,
      name: product.name,
      nameAr: driftValue(product.nameAr),
      nameFr: driftValue(product.nameFr),
      nameEs: driftValue(product.nameEs),
      reference: product.reference,
      category: driftValue(product.category),
      unit: product.unit,
      unitSize: drift.Value(product.unitSize),
      unitsPerBox: drift.Value(product.unitsPerBox),
      purchasePrice: product.purchasePrice,
      sellingPrice: product.sellingPrice,
      tier2Price: driftValue(product.tier2Price),
      tier3Price: driftValue(product.tier3Price),
      minimumStock: drift.Value(product.minimumStock),
      baseMinimumStock: drift.Value(product.baseMinimumStock),
      magazinMinimumStock: drift.Value(product.magazinMinimumStock),
      description: driftValue(product.description),
      imagePath: driftValue(product.imagePath),
      packagingType: driftValue(product.packagingType),
      isActive: driftValue(product.isActive),
      createdAt: driftValue(product.createdAt),
      updatedAt: driftValue(product.updatedAt),
    );
  }

  drift.Value<T> driftValue<T>(T? value) => value == null ? const drift.Value.absent() : drift.Value(value);

  Stream<List<Product>> watchAllProducts() {
    return (_db.select(_db.products)..where((t) => t.isActive.equals(true))).watch().map((entities) => entities.map(_mapToDomain).toList());
  }

  Future<List<Product>> getAllProducts() async {
    final entities = await (_db.select(_db.products)..where((t) => t.isActive.equals(true))).get();
    return entities.map(_mapToDomain).toList();
  }

  Future<void> createProduct(Product product) async {
    await _db.into(_db.products).insert(_mapToCompanion(product));
  }

  Decimal _getBaseValue(String unit) {
    switch (unit.toLowerCase().trim()) {
      case 't':
      case 'm3':
        return Decimal.parse('1000');
      case 'kg':
      case 'l':
        return Decimal.parse('1');
      case 'g':
      case 'ml':
        return Decimal.parse('0.001');
      case 'mg':
        return Decimal.parse('0.000001');
      case 'cl':
        return Decimal.parse('0.01');
      case 'dl':
        return Decimal.parse('0.1');
      default:
        return Decimal.parse('1');
    }
  }

  Decimal _getConversionFactor(String oldUnit, String newUnit) {
    final oldBase = _getBaseValue(oldUnit);
    final newBase = _getBaseValue(newUnit);
    return (oldBase / newBase).toDecimal(scaleOnInfinitePrecision: 6);
  }

  Future<void> updateProduct(Product product) async {
    await _db.transaction(() async {
      final oldProduct = await (_db.select(_db.products)..where((t) => t.id.equals(product.id))).getSingleOrNull();
      
      await (_db.update(_db.products)..where((t) => t.id.equals(product.id))).write(_mapToCompanion(product));
      
      // Stock Conversion Logic
      if (oldProduct != null && oldProduct.unit.toLowerCase().trim() != product.unit.toLowerCase().trim()) {
        final factor = _getConversionFactor(oldProduct.unit, product.unit);
        if (factor != Decimal.one) {
          // Update Stock Balances
          final balances = await (_db.select(_db.stockBalances)..where((t) => t.productId.equals(product.id))).get();
          for (final b in balances) {
             await (_db.update(_db.stockBalances)..where((t) => t.productId.equals(b.productId) & t.locationId.equals(b.locationId))).write(
               StockBalancesCompanion(quantity: drift.Value(b.quantity * factor))
             );
          }
          // Update Stock Movements to maintain mathematical purity and history summing
          final movements = await (_db.select(_db.stockMovements)..where((t) => t.productId.equals(product.id))).get();
          for (final m in movements) {
             await (_db.update(_db.stockMovements)..where((t) => t.id.equals(m.id))).write(
               StockMovementsCompanion(quantity: drift.Value(m.quantity * factor))
             );
          }
        }
      }
      
      // Cascade name updates to auto-generated consumables
      final consumables = await getConsumables(product.id);
      for (final c in consumables) {
        final child = await (_db.select(_db.products)..where((t) => t.id.equals(c.consumableId))).getSingleOrNull();
        if (child != null && child.packagingType != null) {
          // If the child was auto-generated, its reference usually contains the parent's reference
          if (child.reference.startsWith(product.reference)) {
            final newName = '[${child.packagingType}] ${product.name} - ${product.unitSize}${product.unit}';
            if (child.name != newName) {
              await (_db.update(_db.products)..where((t) => t.id.equals(child.id))).write(
                ProductsCompanion(name: drift.Value(newName))
              );
            }
          }
        }
      }
    });
  }

  Future<void> deleteProduct(String id) async {
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(const ProductsCompanion(isActive: drift.Value(false)));
  }
  Future<void> restoreProduct(String id) async {
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(const ProductsCompanion(isActive: drift.Value(true)));
  }
  Future<void> permanentDeleteProduct(String id) async {
    await (_db.delete(_db.products)..where((t) => t.id.equals(id))).go();
  }

  Future<List<ProductConsumableEntity>> getConsumables(String productId) async {
    return await (_db.select(_db.productConsumables)..where((t) => t.productId.equals(productId))).get();
  }

  Future<void> replaceConsumables(String productId, List<Map<String, dynamic>> consumables) async {
    await _db.transaction(() async {
      await (_db.delete(_db.productConsumables)..where((t) => t.productId.equals(productId))).go();
      for (final consumable in consumables) {
         await _db.into(_db.productConsumables).insert(
            ProductConsumablesCompanion.insert(
              productId: productId,
              consumableId: consumable['consumableId'] as String,
              quantityRequired: consumable['quantityRequired'] as Decimal,
            ),
         );
      }
    });
  }
}
