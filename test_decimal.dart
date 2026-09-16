import 'package:decimal/decimal.dart';

void main() {
  print(Decimal.parse('1').toString());
  print(Decimal.parse('1.0').toString());
  print(Decimal.parse('1.50').toString());
}
