import 'package:drift/drift.dart';

@DataClassName('DocumentSequenceEntity')
class DocumentSequences extends Table {
  TextColumn get documentType => text()(); // e.g., 'INVOICE', 'DELIVERY_NOTE'
  TextColumn get prefix => text()(); // e.g., 'FAC-2026'
  IntColumn get lastNumber => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {documentType, prefix};
}
