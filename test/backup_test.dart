import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('Check backup DB image paths', () {
    final srcDir = Directory('/home/limbo/Downloads/Marko-Save');
    final systemBackup = File(p.join(srcDir.path, 'system_backup.sqlite'));
    
    if (systemBackup.existsSync()) {
      final db = sqlite3.open(systemBackup.path);
      
      final products = db.select("SELECT id, name, image_path FROM products WHERE image_path IS NOT NULL;");
      print('--- PRODUCTS ---');
      for (var row in products) {
        print(row);
      }
      
      final clients = db.select("SELECT id, name, image_path FROM clients WHERE image_path IS NOT NULL;");
      print('--- CLIENTS ---');
      for (var row in clients) {
        print(row);
      }
      
      db.dispose();
    } else {
      print('No backup found');
    }
  });
}
