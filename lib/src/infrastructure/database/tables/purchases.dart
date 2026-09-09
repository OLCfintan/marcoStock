import 'package:drift/drift.dart';
import '../../../utils/decimal_converter.dart';

@DataClassName('PurchaseEntity')
class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseNumber => text().unique()();
  TextColumn get documentType => text().withDefault(const Constant('FACTURE'))();
  TextColumn get supplierId => text()();
  
  DateTimeColumn get date => dateTime()();
  
  TextColumn get total => text().map(const DecimalConverter())();
  TextColumn get paidAmount => text().map(const DecimalConverter())();
  
  TextColumn get status => text()(); // 'UNPAID', 'PARTIAL', 'PAID'
  TextColumn get notes => text().nullable()();
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PurchaseLineEntity')
class PurchaseLines extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId => text()();
  TextColumn get productId => text()();
  
  TextColumn get quantity => text().map(const DecimalConverter())();
  TextColumn get unitPrice => text().map(const DecimalConverter())();
  TextColumn get lineTotal => text().map(const DecimalConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
