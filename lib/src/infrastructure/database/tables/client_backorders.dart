import 'package:drift/drift.dart';

class ClientBackorders extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  TextColumn get productId => text()();
  RealColumn get quantity => real()();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
