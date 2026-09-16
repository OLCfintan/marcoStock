import re

filepath = "lib/src/application/stock/stock_helpers.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Add getSIUnit
get_si_unit = """String getSIUnit(String unit) {
  switch (unit.toLowerCase().trim()) {
    case 'ml':
    case 'cl':
    case 'dl':
    case 'l':
      return 'l';
    case 'mg':
    case 'g':
    case 'kg':
    case 't':
      return 'kg';
    case 'm3':
      return 'm3';
    default:
      return unit.toLowerCase().trim();
  }
}

Decimal getConversionFactor"""

content = content.replace("Decimal getConversionFactor", get_si_unit)

# Rewrite convertQuantityToBase
old_convert = r"""Decimal convertQuantityToBase\(Decimal quantity, ProductEntity variant, ProductEntity baseProduct\) \{
  final rawVariantMagnitude = quantity \* variant.unitSize;
  
  // Intelligently infer the real unit from the name to fix bad DB entries like 'Unit' for '250ml' variants
  final variantRealUnit = extractUnitFromName\(variant.name, variant.unit\);
  final baseRealUnit = extractUnitFromName\(baseProduct.name, baseProduct.unit\);
  
  final unitFactor = getConversionFactor\(variantRealUnit, baseRealUnit\);
  final convertedMagnitude = rawVariantMagnitude \* unitFactor;
  return \(convertedMagnitude / baseProduct.unitSize\).toDecimal\(scaleOnInfinitePrecision: 6\);
\}"""

new_convert = r"""Decimal convertQuantityToBase(Decimal quantity, ProductEntity variant, ProductEntity baseProduct) {
  final rawVariantMagnitude = quantity * variant.unitSize;
  
  // Intelligently infer the real unit from the name to fix bad DB entries
  final variantRealUnit = extractUnitFromName(variant.name, variant.unit);
  
  // The user explicitly requested that all mathematical tracking is standardized 
  // into absolute 1L / 1KG / 1M3 standard units, regardless of what the baseProduct is.
  final siUnit = getSIUnit(variantRealUnit);
  
  final unitFactor = getConversionFactor(variantRealUnit, siUnit);
  final convertedMagnitude = rawVariantMagnitude * unitFactor;
  
  // Return the pure magnitude in SI units (divide by 1 since SI unit size is mathematically 1)
  return convertedMagnitude.toDecimal(scaleOnInfinitePrecision: 6);
}"""

content = re.sub(old_convert, new_convert, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated stock_helpers.dart with absolute SI unit math")
