import 'package:sqlite3/sqlite3.dart';
import 'dart:io';

void main() {
  final file = File('/home/limbo/Documents/markogroup_erp.sqlite');
  final db = sqlite3.open(file.path);
  db.execute("UPDATE employees SET is_active = 1 WHERE role = 'ADMIN'");
  print('Admin restored.');
}
