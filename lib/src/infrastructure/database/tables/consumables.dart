import 'package:drift/drift.dart';
import '../../../utils/decimal_converter.dart';

@DataClassName('ProductConsumableEntity')
class ProductConsumables extends Table {
  TextColumn get productId => text()();
  TextColumn get consumableId => text()(); // ID of the product that is consumed
  
  TextColumn get quantityRequired => text().map(const DecimalConverter())();

  @override
  Set<Column> get primaryKey => {productId, consumableId};
}
