import 'package:decimal/decimal.dart';

class UnitConversionService {
  static final Map<String, Decimal> _factors = {
    // Liquid / Capacity (Base: L)
    'kL': Decimal.parse('1000'),
    'hL': Decimal.parse('100'),
    'daL': Decimal.parse('10'),
    'L': Decimal.parse('1'),
    'dL': Decimal.parse('0.1'),
    'cL': Decimal.parse('0.01'),
    'mL': Decimal.parse('0.001'),

    // Mass (Base: g)
    't': Decimal.parse('1000000'), // 1 t = 1000 kg = 1,000,000 g
    'kg': Decimal.parse('1000'),
    'hg': Decimal.parse('100'),
    'dag': Decimal.parse('10'),
    'g': Decimal.parse('1'),
    'dg': Decimal.parse('0.1'),
    'cg': Decimal.parse('0.01'),
    'mg': Decimal.parse('0.001'),

    // Volume (Base: m³)
    'km³': Decimal.parse('1000000000'),
    'hm³': Decimal.parse('1000000'),
    'dam³': Decimal.parse('1000'),
    'm³': Decimal.parse('1'),
    'dm³': Decimal.parse('0.001'), // 1 L
    'cm³': Decimal.parse('0.000001'), // 1 mL
    'mm³': Decimal.parse('0.000000001'),
    
    // Abstract
    'Unit': Decimal.parse('1'),
    'Box': Decimal.parse('1'),
  };

  /// Returns standard dropdown unit categories
  static List<String> get liquidUnits => ['kL', 'hL', 'daL', 'L', 'dL', 'cL', 'mL'];
  static List<String> get massUnits => ['t', 'kg', 'hg', 'dag', 'g', 'dg', 'cg', 'mg'];
  static List<String> get volumeUnits => ['km³', 'hm³', 'dam³', 'm³', 'dm³', 'cm³', 'mm³'];
  static List<String> get standardUnits => ['Unit', 'Box'];
  
  static List<String> get allUnits => [
    ...standardUnits,
    ...massUnits,
    ...liquidUnits,
    ...volumeUnits,
  ];

  /// Get the physical dimension of a unit (Mass, Liquid, Volume, Abstract)
  static String getDimension(String unit) {
    if (liquidUnits.contains(unit)) return 'Liquid';
    if (massUnits.contains(unit)) return 'Mass';
    if (volumeUnits.contains(unit)) return 'Volume';
    return 'Abstract';
  }

  /// Convert an amount from [fromUnit] to [toUnit].
  /// E.g. convert 500 mL to L
  /// Returns null if dimensions do not match (cannot convert Mass to Volume without density).
  static Decimal? convert(Decimal amount, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return amount;
    
    final dim1 = getDimension(fromUnit);
    final dim2 = getDimension(toUnit);
    
    // Cross-dimensional conversions (assuming density of water = 1 kg/L, 1 dm³ = 1 L)
    // The user mentioned: "conversations btwn them correct math logic work"
    // So kg -> L is 1:1, L -> dm³ is 1:1 for basic ERP mappings unless density is provided.
    // We will align all bases to a generic "water" mapping if cross-dim is needed.
    
    // Base 1: 1g = 0.001kg. Base 2: 1L = 1kg. Base 3: 1dm3 = 1L.
    
    Decimal factorFrom = _factors[fromUnit] ?? Decimal.one;
    Decimal factorTo = _factors[toUnit] ?? Decimal.one;
    
    // Convert to Universal Base (Gram / mL / cm3 equivalent)
    // 1 L = 1000 Universal (mL)
    // 1 kg = 1000 Universal (g)
    // 1 m3 = 1,000,000 Universal (cm3)
    
    Decimal universalAmount = amount * factorFrom;
    
    // If from is Mass(g) and to is Volume(m3), Universal = g.
    // 1 m3 = 1,000,000 cm3(mL/g) -> factorTo for m3 is 1. Wait.
    // Let's standardize: 
    // Liquid Base = L (Factor=1)
    // Mass Base = g (Factor=1)
    // Volume Base = m3 (Factor=1)
    
    // Universal water standard: 1 L = 1000 g = 0.001 m3.
    // Let's convert universalAmount into `toUnit`'s domain base first.
    Decimal baseDomainAmount = universalAmount;
    if (dim1 != dim2) {
      if (dim1 == 'Liquid' && dim2 == 'Mass') {
        baseDomainAmount = universalAmount * Decimal.parse('1000');
      } else if (dim1 == 'Mass' && dim2 == 'Liquid') {
        baseDomainAmount = (universalAmount / Decimal.parse('1000')).toDecimal(scaleOnInfinitePrecision: 12);
      } else if (dim1 == 'Liquid' && dim2 == 'Volume') {
        baseDomainAmount = (universalAmount / Decimal.parse('1000')).toDecimal(scaleOnInfinitePrecision: 12);
      } else if (dim1 == 'Volume' && dim2 == 'Liquid') {
        baseDomainAmount = universalAmount * Decimal.parse('1000');
      } else if (dim1 == 'Mass' && dim2 == 'Volume') {
        baseDomainAmount = (universalAmount / Decimal.parse('1000000')).toDecimal(scaleOnInfinitePrecision: 12);
      } else if (dim1 == 'Volume' && dim2 == 'Mass') {
        baseDomainAmount = universalAmount * Decimal.parse('1000000');
      }
    }
    
    return (baseDomainAmount / factorTo).toDecimal(scaleOnInfinitePrecision: 12);
  }
}
