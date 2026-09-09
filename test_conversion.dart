import 'package:decimal/decimal.dart';

Decimal getBaseValue(String unit) {
  unit = unit.toLowerCase().trim();
  switch (unit) {
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
      return Decimal.parse('1'); // Unrecognized, assume 1:1
  }
}

Decimal getConversionFactor(String oldUnit, String newUnit) {
  final oldBase = getBaseValue(oldUnit);
  final newBase = getBaseValue(newUnit);
  // If moving from Kg (1) to g (0.001), 1 / 0.001 = 1000.
  // We need to multiply the stock by 1000.
  // 5 Kg -> 5 * (1 / 0.001) = 5000 g
  // So factor = oldBase / newBase
  return (oldBase / newBase).toDecimal(scaleOnInfinitePrecision: 6);
}

void main() {
  print('Kg to g: ${getConversionFactor('Kg', 'g')}');
  print('m3 to l: ${getConversionFactor('m3', 'L')}');
  print('g to cl: ${getConversionFactor('g', 'cl')}');
  print('kg to l: ${getConversionFactor('kg', 'l')}');
}
