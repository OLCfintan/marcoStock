import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('/home/limbo/Documents/markogroup_erp.sqlite');
  final resultSet = db.select("SELECT name, nameAr FROM products WHERE name LIKE '%Diluant%';");
  for (final row in resultSet) {
    print('${row['name']} -> ${row['nameAr']}');
  }
}
