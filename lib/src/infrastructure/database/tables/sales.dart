import 'package:drift/drift.dart';
import '../../../utils/decimal_converter.dart';

@DataClassName('InvoiceEntity')
class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceNumber => text().unique()();
  TextColumn get documentType => text().withDefault(const Constant('FACTURE'))();
  TextColumn get clientId => text().nullable()();
  
  DateTimeColumn get date => dateTime()();
  
  TextColumn get subtotal => text().map(const DecimalConverter())();
  TextColumn get taxes => text().map(const DecimalConverter())();
  TextColumn get total => text().map(const DecimalConverter())();
  TextColumn get paidAmount => text().map(const DecimalConverter())();
  
  TextColumn get status => text()(); // 'UNPAID', 'PARTIAL', 'PAID'
  TextColumn get notes => text().nullable()();
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InvoiceLineEntity')
class InvoiceLines extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text()();
  TextColumn get productId => text()();
  
  TextColumn get quantity => text().map(const DecimalConverter())();
  TextColumn get unitPrice => text().map(const DecimalConverter())();
  TextColumn get discount => text().map(const DecimalConverter())();
  TextColumn get lineTotal => text().map(const DecimalConverter())();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PaymentEntity')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text().nullable()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get employeeId => text().nullable()();
  TextColumn get invoiceId => text().nullable()();
  TextColumn get purchaseId => text().nullable()();
  
  TextColumn get amount => text().map(const DecimalConverter())();
  TextColumn get method => text()(); // 'CASH', 'TRANSFER', 'CHECK'
  TextColumn get reference => text().nullable()();
  TextColumn get checkImagePath => text().nullable()();
  
  DateTimeColumn get date => dateTime()();
  TextColumn get status => text()(); // 'CLEARED', 'PENDING'
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AuditLogEntity')
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get action => text()(); // e.g. 'CREATE_INVOICE'
  TextColumn get entityType => text()(); // e.g. 'INVOICE'
  TextColumn get entityId => text()();
  TextColumn get details => text()(); // JSON
  
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
