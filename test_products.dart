import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final path = '/home/limbo/.local/share/com.example.marcostock/app_database.sqlite'; // guessing
  if (!File(path).existsSync()) {
    print('DB not found at $path');
    return;
  }
  final db = sqlite3.open(path);
  final resultSet = db.select('SELECT name, nameAr FROM products;');
  for (final row in resultSet) {
    print('${row['name']} -> ${row['nameAr']}');
  }
}
