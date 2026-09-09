import 'package:drift/drift.dart';
import '../../../utils/decimal_converter.dart';

@DataClassName('ClientEntity')
class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get contactDetails => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get businessInformation => text().nullable()();
  TextColumn get tier => text().withDefault(const Constant('Tier 1'))();
  TextColumn get type => text().withDefault(const Constant('NORMAL'))();
  
  // Positive balance means debt owed to MarkoGroup
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
