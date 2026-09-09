import 'package:drift/drift.dart';
import '../../../utils/decimal_converter.dart';

@DataClassName('EmployeeEntity')
class Employees extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get position => text()();
  
  // Base fixed salary
  TextColumn get baseSalary => text().map(const DecimalConverter()).withDefault(const Constant('0'))();
  
  // Live computed balance (Negative = we owe them, Positive = they owe us/advance)
  // Let's use standard convention: Positive balance = Money owed to employee
  TextColumn get remainingSalary => text().map(const DecimalConverter()).withDefault(const Constant('0'))();
  
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get idScanPath => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('CASHIER'))();
  TextColumn get pinCode => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PayrollRecordEntity')
class PayrollRecords extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text()();
  
  // 'SALARY', 'ADVANCE', 'BONUS', 'DEDUCTION', 'PAYMENT'
  TextColumn get type => text()();
  
  TextColumn get amount => text().map(const DecimalConverter())();
  TextColumn get notes => text().nullable()();
  
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EmployeeActivityEntity')
class EmployeeActivities extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text()();
  
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();
  
  RealColumn get workedHours => real().nullable()();
  TextColumn get activityType => text().nullable()(); // 'PRODUCTION', 'STOCK', etc
  TextColumn get productId => text().nullable()();
  IntColumn get boxesCompleted => integer().nullable()();
  
  // Integration ID from external AI system if applicable
  TextColumn get externalReferenceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
