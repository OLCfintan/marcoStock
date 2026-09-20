import 'package:drift/drift.dart';
import '../../../utils/decimal_converter.dart';

@DataClassName('ProductEntity')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get nameAr => text().nullable()();
  TextColumn get nameFr => text().nullable()();
  TextColumn get nameEs => text().nullable()();
  TextColumn get reference => text().withLength(min: 1, max: 255).unique()();
  TextColumn get category => text().nullable()();
  TextColumn get unit => text().withLength(min: 1, max: 50)();
  TextColumn get unitSize => text().map(const DecimalConverter()).withDefault(const Constant('1'))();
  
  // Stored as text to maintain absolute precision, mapped to Decimal
  TextColumn get purchasePrice => text().map(const DecimalConverter())();
  TextColumn get sellingPrice => text().map(const DecimalConverter())();
  TextColumn get minimumStock => text().map(const DecimalConverter()).withDefault(const Constant('0'))();
  TextColumn get baseMinimumStock => text().map(const DecimalConverter()).withDefault(const Constant('0'))();
  TextColumn get magazinMinimumStock => text().map(const DecimalConverter()).withDefault(const Constant('0'))();
  
  TextColumn get description => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get tier2Price => text().map(const DecimalConverter()).nullable()();
  TextColumn get tier3Price => text().map(const DecimalConverter()).nullable()();
  TextColumn get packagingType => text().nullable()();
  IntColumn get unitsPerBox => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}


@DataClassName('ProductRelationEntity')
class ProductRelations extends Table {
  TextColumn get id => text()();
  TextColumn get parentProductId => text()();
  TextColumn get childProductId => text()();
  TextColumn get quantity => text().map(const DecimalConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
