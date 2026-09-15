import '../../infrastructure/database/app_database.dart';
import 'package:decimal/decimal.dart';

Future<ProductEntity> getDeterministicBaseProduct(AppDatabase db, ProductEntity product) async {
  if (product.unitSize == Decimal.one && product.packagingType == 'Unit') {
    return product;
  }
  
  final familyProducts = await (db.select(db.products)..where((t) => t.name.equals(product.name))).get();
  
  if (familyProducts.isEmpty) return product;

  familyProducts.sort((a, b) {
    // 1. Prefer unitSize == 1
    if (a.unitSize == Decimal.one && b.unitSize != Decimal.one) return -1;
    if (b.unitSize == Decimal.one && a.unitSize != Decimal.one) return 1;
    
    // 2. Prefer packagingType == 'Unit'
    final aIsUnit = (a.packagingType == 'Unit');
    final bIsUnit = (b.packagingType == 'Unit');
    if (aIsUnit && !bIsUnit) return -1;
    if (bIsUnit && !aIsUnit) return 1;
    
    // 3. Fallback to older createdAt (stable deterministic tie-breaker)
    return a.createdAt.compareTo(b.createdAt);
  });
  
  return familyProducts.first;
}

Decimal getBaseValue(String unit) {
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

Decimal getConversionFactor(String oldUnit, String newUnit) {
  final oldBase = getBaseValue(oldUnit);
  final newBase = getBaseValue(newUnit);
  return (oldBase / newBase).toDecimal(scaleOnInfinitePrecision: 6);
}

Decimal convertQuantityToBase(Decimal quantity, ProductEntity variant, ProductEntity baseProduct) {
  final rawVariantMagnitude = quantity * variant.unitSize;
  final unitFactor = getConversionFactor(variant.unit, baseProduct.unit);
  final convertedMagnitude = rawVariantMagnitude * unitFactor;
  return (convertedMagnitude / baseProduct.unitSize).toDecimal(scaleOnInfinitePrecision: 6);
}
