import re

filepath = "lib/src/presentation/purchases/purchases_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Add import for stock_helpers if missing
if "import '../../application/stock/stock_helpers.dart';" not in content:
    content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../../application/stock/stock_helpers.dart';")

old_products = r"""      final products = allProducts\.where\(\(p\) => p\.isActive\)\.toList\(\);
        products\.sort\(\(a, b\) => a\.name\.compareTo\(b\.name\)\);"""

new_products = r"""      // Get one base product per family
      final Map<String, Product> familyBases = {};
      for (final p in allProducts.where((p) => p.isActive)) {
        final family = extractFamilyName(p.name);
        if (!familyBases.containsKey(family)) {
          familyBases[family] = p;
        } else {
          // Prefer unitSize == 1
          if (p.unitSize == Decimal.one && familyBases[family]!.unitSize != Decimal.one) {
            familyBases[family] = p;
          } else if (p.unitSize == Decimal.one && familyBases[family]!.unitSize == Decimal.one) {
            // Prefer packaging type Vrac or Unit
            if (p.packagingType?.toLowerCase() == 'vrac' || p.packagingType?.toLowerCase() == 'unit') {
              familyBases[family] = p;
            }
          }
        }
      }
      final products = familyBases.values.toList();
      products.sort((a, b) => a.name.compareTo(b.name));"""

content = re.sub(old_products, new_products, content, flags=re.MULTILINE | re.DOTALL)

# Let's ensure the label displays the base unit nicely
old_label = r"""                                Text(
                                  '${p.unitSize.toString()} ${p.unit}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                                ),"""

new_label = r"""                                Text(
                                  'Base Unit: 1 ${p.unit.toUpperCase()}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 10),
                                ),"""

content = re.sub(old_label, new_label, content, flags=re.MULTILINE | re.DOTALL)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
