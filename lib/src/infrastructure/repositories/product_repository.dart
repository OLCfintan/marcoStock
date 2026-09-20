import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../application/stock/stock_helpers.dart';

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
      nameAr: drift.Value(product.nameAr),
      nameFr: drift.Value(product.nameFr),
      nameEs: drift.Value(product.nameEs),
      reference: product.reference,
      category: drift.Value(product.category),
      unit: product.unit,
      unitSize: drift.Value(product.unitSize),
      unitsPerBox: drift.Value(product.unitsPerBox),
      purchasePrice: product.purchasePrice,
      sellingPrice: product.sellingPrice,
      tier2Price: drift.Value(product.tier2Price),
      tier3Price: drift.Value(product.tier3Price),
      minimumStock: drift.Value(product.minimumStock),
      baseMinimumStock: drift.Value(product.baseMinimumStock),
      magazinMinimumStock: drift.Value(product.magazinMinimumStock),
      description: drift.Value(product.description),
      imagePath: drift.Value(product.imagePath),
      packagingType: drift.Value(product.packagingType),
      isActive: drift.Value(product.isActive),
      createdAt: drift.Value(product.createdAt),
      updatedAt: drift.Value(product.updatedAt),
    );
  }

  drift.Value<T> driftValue<T>(T? value) => value == null ? const drift.Value.absent() : drift.Value(value);

  Future<void> updateProductReorder(List<Product> products) async {
    await _db.transaction(() async {
      for (int i = 0; i < products.length; i++) {
        await (_db.update(_db.products)..where((t) => t.id.equals(products[i].id))).write(ProductsCompanion(displayOrder: drift.Value(i)));
      }
    });
  }

  Stream<List<Product>> watchAllProducts() {
    return (_db.select(_db.products)..where((t) => t.isActive.equals(true))..orderBy([(t) => drift.OrderingTerm(expression: t.displayOrder)])).watch().map((entities) => entities.map(_mapToDomain).toList());
  }

  Future<List<Product>> getAllProducts() async {
    final entities = await (_db.select(_db.products)..where((t) => t.isActive.equals(true))..orderBy([(t) => drift.OrderingTerm(expression: t.displayOrder)])).get();
    return entities.map(_mapToDomain).toList();
  }

  Future<void> createProduct(Product product) async {
    await _db.transaction(() async {
      await _db.into(_db.products).insert(_mapToCompanion(product));
      
      // Auto-create 1L/1KG base product if it doesn't exist
      if (product.unitSize != Decimal.one) {
        final familyName = extractFamilyName(product.name);
        final allProducts = await (_db.select(_db.products)..where((t) => t.isActive.equals(true))).get();
        
        bool hasBase = false;
        for (final p in allProducts) {
          if (extractFamilyName(p.name) == familyName && p.unitSize == Decimal.one) {
            hasBase = true;
            break;
          }
        }
        
        if (!hasBase) {
          // Create the base product mathematically
          final basePrice = product.sellingPrice != Decimal.zero && product.unitSize > Decimal.zero 
            ? (product.sellingPrice / product.unitSize).toDecimal(scaleOnInfinitePrecision: 2) 
            : Decimal.zero;
          final basePurchasePrice = product.purchasePrice != Decimal.zero && product.unitSize > Decimal.zero 
            ? (product.purchasePrice / product.unitSize).toDecimal(scaleOnInfinitePrecision: 2) 
            : Decimal.zero;
          
          final defaultUnit = getBaseUnitFor(product.unit);
            
          final baseProduct = Product(
            id: const Uuid().v4(),
            name: '${familyName.toUpperCase()} 1${defaultUnit.toUpperCase()}', // e.g. DILUANT MARKO 1L
            reference: '${product.reference.substring(0, min(6, product.reference.length))}-BASE',
            unit: defaultUnit,
            unitSize: Decimal.one,
            packagingType: 'Vrac',
            unitsPerBox: 1,
            purchasePrice: basePurchasePrice,
            sellingPrice: basePrice,
            tier2Price: null,
            tier3Price: null,
            minimumStock: product.minimumStock,
            baseMinimumStock: product.baseMinimumStock,
            magazinMinimumStock: product.magazinMinimumStock,
            imagePath: product.imagePath,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await _db.into(_db.products).insert(_mapToCompanion(baseProduct));
        }
      }
    });
  }

  String getBaseUnitFor(String currentUnit) {
    switch (currentUnit.toLowerCase().trim()) {
      case 'g':
      case 'mg':
      case 'kg':
        return 'KG';
      case 'ml':
      case 'cl':
      case 'dl':
      case 'l':
        return 'L';
      case 'm3':
        return 'M3';
      default:
        return currentUnit;
    }
  }

  int min(int a, int b) => a < b ? a : b;


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
