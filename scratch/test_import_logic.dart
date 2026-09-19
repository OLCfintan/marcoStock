import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() async {
  final srcDir = Directory('/home/limbo/Downloads/Marko-Save');
  final systemBackup = File(p.join(srcDir.path, 'system_backup.sqlite'));
  final markoAssetsDir = Directory('/tmp/marko_assets');
  if (!await markoAssetsDir.exists()) await markoAssetsDir.create();

  final tempDbFile = File('/tmp/temp_restore.sqlite');
  await systemBackup.copy(tempDbFile.path);
  
  final tempDb = sqlite3.open(tempDbFile.path);

  final products = tempDb.select("SELECT id, image_path FROM products WHERE image_path IS NOT NULL AND image_path != '';");
  print('Found ${products.length} products with images in backup db');
  
  for (var row in products) {
    final id = row['id'] as String;
    final oldPathOrName = row['image_path'] as String;
    final basename = p.basename(oldPathOrName);
    
    File expectedExportPath = File(p.join(srcDir.path, 'Products', 'images', basename));
    print('Checking expected path: ${expectedExportPath.path}');
    if (!await expectedExportPath.exists()) {
      print('  -> Does not exist. Falling back to old format');
      expectedExportPath = File(p.join(srcDir.path, 'Products', 'images', '${id}_$basename'));
    }
    
    if (await expectedExportPath.exists()) {
      print('  -> FOUND IT! Copying...');
      final newAssetPath = File(p.join(markoAssetsDir.path, 'prod_${id}_$basename'));
      // await expectedExportPath.copy(newAssetPath.path);
      // tempDb.execute("UPDATE products SET image_path = ? WHERE id = ?", [newAssetPath.path, id]);
    } else {
      print('  -> STILL NOT FOUND in export directory!');
    }
  }

  tempDb.dispose();
}
