import 'package:sqlite3/sqlite3.dart';
import 'dart:io';

void main() {
  final file = File('/home/limbo/Documents/markogroup_erp.sqlite');
  if (!file.existsSync()) {
    print('DB not found at Documents.');
    return;
  }
  final db = sqlite3.open(file.path);
  final result = db.select('SELECT id, name, role, pin_code, is_active FROM employees');
  print('Employees:');
  for (var r in result) {
    print(r);
  }
}
