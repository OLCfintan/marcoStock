import re

filepath = "lib/src/infrastructure/repositories/product_repository.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Make sure to import uuid and stock_helpers
if "import 'package:uuid/uuid.dart';" not in content:
    content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:uuid/uuid.dart';\nimport '../../application/stock/stock_helpers.dart';")

old_create = r"""  Future<void> createProduct\(Product product\) async \{
    await _db\.into\(_db\.products\)\.insert\(_mapToCompanion\(product\)\);
  \}"""

new_create = r"""  Future<void> createProduct(Product product) async {
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
            name: familyName.toUpperCase() + ' 1' + defaultUnit.toUpperCase(), // e.g. DILUANT MARKO 1L
            reference: product.reference.substring(0, min(6, product.reference.length)) + '-BASE',
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
"""

content = re.sub(old_create, new_create, content, flags=re.MULTILINE | re.DOTALL)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
