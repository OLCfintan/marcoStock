import re

# 1. product.dart
f1 = "lib/src/domain/products/product.dart"
with open(f1, 'r') as f:
    c = f.read()
c = c.replace("return unitSize == Decimal.one ? '$n $unit' : '$n $unitSize$unit';", "return '$n $unitSize$unit';")
with open(f1, 'w') as f:
    f.write(c)

# 2. stock_screen.dart
f2 = "lib/src/presentation/stock/stock_screen.dart"
with open(f2, 'r') as f:
    c = f.read()
c = c.replace("title: Text(item.unitSize == Decimal.one ? '${item.productName} ${item.unit}' : '${item.productName} ${item.unitSize}${item.unit}'),",
              "title: Text('${item.productName} ${item.unitSize}${item.unit}'),")
with open(f2, 'w') as f:
    f.write(c)

# 3. purchases_screen.dart
f3 = "lib/src/presentation/purchases/purchases_screen.dart"
with open(f3, 'r') as f:
    c = f.read()
c = c.replace("(${p.unitSize == Decimal.one ? p.unit : '${p.unitSize}${p.unit}'})", "(${p.unitSize}${p.unit})")
with open(f3, 'w') as f:
    f.write(c)

# 4. pdf_generator.dart
f4 = "lib/src/application/documents/pdf_generator.dart"
with open(f4, 'r') as f:
    c = f.read()
old_pdf = r"""    if \(unitSize == Decimal\.one\) \{
      return '\$finalName \$unit';
    \} else \{
      return '\$finalName \$unitSize\$unit';
    \}"""
new_pdf = r"""    return '$finalName $unitSize$unit';"""
c = re.sub(old_pdf, new_pdf, c, flags=re.MULTILINE)
with open(f4, 'w') as f:
    f.write(c)

# 5. dashboard_providers.dart
f5 = "lib/src/application/dashboard/dashboard_providers.dart"
with open(f5, 'r') as f:
    c = f.read()
c = c.replace("final baseLabel = rootProduct.unitSize == Decimal.one ? ' ${rootProduct.unit}' : ' ${rootProduct.unitSize}${rootProduct.unit}';",
              "final baseLabel = ' ${rootProduct.unitSize}${rootProduct.unit}';")
with open(f5, 'w') as f:
    f.write(c)

print("Formatting updated.")
