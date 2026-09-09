import 'package:drift/drift.dart';
import '../../../utils/decimal_converter.dart';

@DataClassName('StockLocationEntity')
class StockLocations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get type => text()(); // 'BASE' or 'CLIENT'
  TextColumn get referenceId => text().nullable()(); // Client ID if type is CLIENT
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StockMovementEntity')
class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get sourceLocationId => text().nullable()(); // null if inbound purchase
  TextColumn get targetLocationId => text().nullable()(); // null if outbound consumption/loss
  
  TextColumn get quantity => text().map(const DecimalConverter())();
  
  TextColumn get reason => text()(); // 'SALE', 'PURCHASE', 'TRANSFER', 'ADJUSTMENT'
  TextColumn get referenceOperationId => text().nullable()(); // e.g., Invoice ID
  
  TextColumn get createdBy => text()(); // User ID for audit
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StockBalanceEntity')
class StockBalances extends Table {
  TextColumn get productId => text()();
  TextColumn get locationId => text()();
  
  TextColumn get quantity => text().map(const DecimalConverter())();
  
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {productId, locationId};
}
