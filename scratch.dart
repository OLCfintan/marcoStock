import 'package:decimal/decimal.dart';

void main() {
  Decimal d = Decimal.fromInt(10);
  print(d.toBigInt());
  print(d.toBigInt().toDecimal());
}
