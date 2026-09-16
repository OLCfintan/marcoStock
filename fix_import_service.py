import re

filepath = "lib/src/application/import/import_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_product_block = r"""          \} else if \(type == 'PRODUCT'\) \{
            await _db\.into\(_db\.products\)\.insert\(ProductsCompanion\(
              id: drift\.Value\(_uuid\.v4\(\)\),
              name: drift\.Value\(map\['NAME'\] \?\? 'Unknown Product'\),
              nameAr: map\['NAMEAR'\] != null \? drift\.Value\(map\['NAMEAR'\]\) : const drift\.Value\.absent\(\),
              nameFr: map\['NAMEFR'\] != null \? drift\.Value\(map\['NAMEFR'\]\) : const drift\.Value\.absent\(\),
              nameEs: map\['NAMEES'\] != null \? drift\.Value\(map\['NAMEES'\]\) : const drift\.Value\.absent\(\),
              reference: drift\.Value\(map\['REFERENCE'\] \?\? _uuid\.v4\(\)\.substring\(0, 8\)\.toUpperCase\(\)\),
              unit: drift\.Value\(\(\) \{
                final u = map\['UNIT'\] \?\? 'Unit';
                return UnitConversionService\.allUnits\.contains\(u\) \? u : 
                  \(UnitConversionService\.allUnits\.contains\(u\.toLowerCase\(\)\) \? u\.toLowerCase\(\) : 
                  \(UnitConversionService\.allUnits\.contains\(u\.toUpperCase\(\)\) \? u\.toUpperCase\(\) : 'Unit'\)\);
              \}\(\)\),
              unitSize: drift\.Value\(Decimal\.tryParse\(map\['UNITSIZE'\] \?\? ''\) \?\? Decimal\.one\),
              unitsPerBox: drift\.Value\(int\.tryParse\(map\['UNITSPERBOX'\] \?\? map\['BOXUNITS'\] \?\? ''\) \?\? 1\),
              purchasePrice: drift\.Value\(Decimal\.tryParse\(map\['PURCHASEPRICE'\] \?\? ''\) \?\? Decimal\.zero\),
              sellingPrice: drift\.Value\(Decimal\.tryParse\(map\['PRICE'\] \?\? map\['SELLINGPRICE'\] \?\? ''\) \?\? Decimal\.zero\),
              minimumStock: drift\.Value\(Decimal\.tryParse\(map\['MINSTOCK'\] \?\? ''\) \?\? Decimal\.zero\),
              baseMinimumStock: drift\.Value\(Decimal\.tryParse\(map\['BASEMINSTOCK'\] \?\? ''\) \?\? Decimal\.zero\),
              magazinMinimumStock: drift\.Value\(Decimal\.tryParse\(map\['MAGAZINMINSTOCK'\] \?\? ''\) \?\? Decimal\.zero\),
              tier2Price: drift\.Value\(Decimal\.tryParse\(map\['TIER2PRICE'\] \?\? '0'\) \?\? Decimal\.zero\),
              tier3Price: drift\.Value\(Decimal\.tryParse\(map\['TIER3PRICE'\] \?\? '0'\) \?\? Decimal\.zero\),
              packagingType: drift\.Value\(\(\) \{
                 final p = map\['PACKAGING'\] \?\? 'Unit';
                 final opts = \['Unit', 'Box', 'Ticket', 'Bottle'\];
                 return opts\.contains\(p\) \? p : \(opts\.map\(\(o\) => o\.toLowerCase\(\)\)\.contains\(p\.toLowerCase\(\)\) \? 
                        opts\.firstWhere\(\(o\) => o\.toLowerCase\(\) == p\.toLowerCase\(\)\) : 'Unit'\);
              \}\(\)\),
            \)\);
            productsAdded\+\+;
          \}"""

new_product_block = r"""          } else if (type == 'PRODUCT') {
            final refVal = map['REFERENCE'] ?? _uuid.v4().substring(0, 8).toUpperCase();
            final existingProduct = await (_db.select(_db.products)..where((t) => t.reference.equals(refVal))).getSingleOrNull();
            
            final companion = ProductsCompanion(
              name: drift.Value(map['NAME'] ?? (existingProduct?.name ?? 'Unknown Product')),
              nameAr: map['NAMEAR'] != null ? drift.Value(map['NAMEAR']) : const drift.Value.absent(),
              nameFr: map['NAMEFR'] != null ? drift.Value(map['NAMEFR']) : const drift.Value.absent(),
              nameEs: map['NAMEES'] != null ? drift.Value(map['NAMEES']) : const drift.Value.absent(),
              reference: drift.Value(refVal),
              unit: drift.Value(() {
                final u = map['UNIT'] ?? existingProduct?.unit ?? 'Unit';
                return UnitConversionService.allUnits.contains(u) ? u : 
                  (UnitConversionService.allUnits.contains(u.toLowerCase()) ? u.toLowerCase() : 
                  (UnitConversionService.allUnits.contains(u.toUpperCase()) ? u.toUpperCase() : 'Unit'));
              }()),
              unitSize: drift.Value(Decimal.tryParse(map['UNITSIZE'] ?? '') ?? existingProduct?.unitSize ?? Decimal.one),
              unitsPerBox: drift.Value(int.tryParse(map['UNITSPERBOX'] ?? map['BOXUNITS'] ?? '') ?? existingProduct?.unitsPerBox ?? 1),
              purchasePrice: drift.Value(Decimal.tryParse(map['PURCHASEPRICE'] ?? '') ?? existingProduct?.purchasePrice ?? Decimal.zero),
              sellingPrice: drift.Value(Decimal.tryParse(map['PRICE'] ?? map['SELLINGPRICE'] ?? '') ?? existingProduct?.sellingPrice ?? Decimal.zero),
              minimumStock: drift.Value(Decimal.tryParse(map['MINSTOCK'] ?? '') ?? existingProduct?.minimumStock ?? Decimal.zero),
              baseMinimumStock: drift.Value(Decimal.tryParse(map['BASEMINSTOCK'] ?? '') ?? existingProduct?.baseMinimumStock ?? Decimal.zero),
              magazinMinimumStock: drift.Value(Decimal.tryParse(map['MAGAZINMINSTOCK'] ?? '') ?? existingProduct?.magazinMinimumStock ?? Decimal.zero),
              tier2Price: drift.Value(Decimal.tryParse(map['TIER2PRICE'] ?? '0') ?? existingProduct?.tier2Price ?? Decimal.zero),
              tier3Price: drift.Value(Decimal.tryParse(map['TIER3PRICE'] ?? '0') ?? existingProduct?.tier3Price ?? Decimal.zero),
              packagingType: drift.Value(() {
                 final p = map['PACKAGING'] ?? existingProduct?.packagingType ?? 'Unit';
                 final opts = ['Unit', 'Box', 'Ticket', 'Bottle'];
                 return opts.contains(p) ? p : (opts.map((o) => o.toLowerCase()).contains(p.toLowerCase()) ? 
                        opts.firstWhere((o) => o.toLowerCase() == p.toLowerCase()) : 'Unit');
              }()),
            );

            if (existingProduct != null) {
              await (_db.update(_db.products)..where((t) => t.id.equals(existingProduct.id))).write(companion);
            } else {
              await _db.into(_db.products).insert(companion.copyWith(id: drift.Value(_uuid.v4())));
            }
            productsAdded++;
          }"""

content = re.sub(old_product_block, new_product_block, content)
with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
