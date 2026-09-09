import 'package:drift/drift.dart';
import '../../../utils/decimal_converter.dart';

@DataClassName('SupplierEntity')
class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get type => text().withDefault(const Constant('NORMAL'))(); // 'NORMAL' or 'SPECIAL'
  TextColumn get contactDetails => text().nullable()();
  
  // Positive balance means MarkoGroup owes money to the supplier
  TextColumn get balance => text().map(const DecimalConverter()).withDefault(const Constant('0'))();
  
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
