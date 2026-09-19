import 'package:sqlite3/sqlite3.dart';
void main() {
  final db = sqlite3.open('/home/limbo/Downloads/Marko-Save/system_backup.sqlite');
  final res = db.select('SELECT id, name, image_path FROM products WHERE image_path IS NOT NULL LIMIT 5;');
  for (var row in res) {
    print(row);
  }
  db.dispose();
}
