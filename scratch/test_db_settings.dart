import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath = '/home/limbo/Documents/markogroup_erp.sqlite';
  final db = sqlite3.open(dbPath);
  final result = db.select("SELECT * FROM settings WHERE key IN ('companyInvoiceAddress', 'companyTp')");
  print('Found ${result.length} settings');
  for (var row in result) {
    print('${row['key']}: ${row['value']}');
  }
  db.dispose();
}
