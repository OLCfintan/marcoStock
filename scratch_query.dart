import 'package:sqlite3/sqlite3.dart';
import 'dart:io';

void main() {
  final file = File('/home/limbo/Documents/markogroup_erp.sqlite');
  if (!file.existsSync()) {
    print('DB not found at Documents.');
    return;
  }
  final db = sqlite3.open(file.path);
  final result = db.select('SELECT count(*) as c FROM products');
  print('Products count: ${result.first['c']}');
  
  final res2 = db.select('SELECT * FROM products LIMIT 5');
  for (var r in res2) {
    print(r);
  }
}
