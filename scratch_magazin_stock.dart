import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath = '${Platform.environment['HOME']}/Documents/markogroup_erp.sqlite';
  final db = sqlite3.open(dbPath);
  final rs = db.select("SELECT * FROM stock_balances WHERE location_id = 'MAGAZIN_01'");
  print("Count: ${rs.length}");
  for (final row in rs) {
    print(row);
  }
}
