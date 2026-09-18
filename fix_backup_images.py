import re

filepath = "lib/src/application/backup/backup_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Make sure sqlite3 is imported
if "import 'package:sqlite3/sqlite3.dart' as sqlite;" not in content:
    content = content.replace("import 'package:path/path.dart' as p;", "import 'package:path/path.dart' as p;\nimport 'package:sqlite3/sqlite3.dart' as sqlite;")

# Replace the current importData method
old_import = r"""  Future<void> importData\(\) async \{.*?\}
\}"""

new_import = r"""  Future<void> importData() async {
    final srcDirStr = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Marko-Save folder to import');
    if (srcDirStr == null) return;

    final srcDir = Directory(srcDirStr);
    final systemBackup = File(p.join(srcDir.path, 'system_backup.sqlite'));

    if (!await systemBackup.exists()) {
      throw Exception('Valid Marko-Save system_backup.sqlite not found in the selected folder!');
    }

    final appDocs = await getApplicationDocumentsDirectory();
    final markoAssetsDir = Directory(p.join(appDocs.path, 'marko_assets'));
    if (!await markoAssetsDir.exists()) {
      await markoAssetsDir.create(recursive: true);
    }

    // 1. Copy backup to a temporary file so we can safely mutate image paths BEFORE overwriting active DB
    final tempDbFile = File(p.join(appDocs.path, 'temp_restore.sqlite'));
    await systemBackup.copy(tempDbFile.path);

    // 2. Open temporary DB with raw sqlite3
    final tempDb = sqlite.sqlite3.open(tempDbFile.path);

    // 3. Process Products Images Dynamic Mapping
    final products = tempDb.select("SELECT id, imagePath FROM products WHERE imagePath IS NOT NULL AND imagePath != '';");
    for (var row in products) {
      final id = row['id'] as String;
      final oldPath = row['imagePath'] as String;
      final basename = p.basename(oldPath);
      
      final expectedExportPath = File(p.join(srcDir.path, 'Products', 'images', '${id}_$basename'));
      final newAssetPath = File(p.join(markoAssetsDir.path, 'prod_${id}_$basename'));
      
      if (await expectedExportPath.exists()) {
        await expectedExportPath.copy(newAssetPath.path);
        tempDb.execute("UPDATE products SET imagePath = ? WHERE id = ?", [newAssetPath.path, id]);
      }
    }

    // 4. Process Clients Images Dynamic Mapping
    final clients = tempDb.select("SELECT id, name, imagePath FROM clients WHERE imagePath IS NOT NULL AND imagePath != '';");
    for (var row in clients) {
      final id = row['id'] as String;
      final name = row['name'] as String;
      final oldPath = row['imagePath'] as String;
      final basename = p.basename(oldPath);
      
      final cleanName = _cleanFileName(name);
      final expectedExportPath = File(p.join(srcDir.path, 'Clients', cleanName, 'profileImage_$basename'));
      final newAssetPath = File(p.join(markoAssetsDir.path, 'client_${id}_$basename'));
      
      if (await expectedExportPath.exists()) {
        await expectedExportPath.copy(newAssetPath.path);
        tempDb.execute("UPDATE clients SET imagePath = ? WHERE id = ?", [newAssetPath.path, id]);
      }
    }

    // 5. Process Suppliers Images Dynamic Mapping
    final suppliers = tempDb.select("SELECT id, name, imagePath FROM suppliers WHERE imagePath IS NOT NULL AND imagePath != '';");
    for (var row in suppliers) {
      final id = row['id'] as String;
      final name = row['name'] as String;
      final oldPath = row['imagePath'] as String;
      final basename = p.basename(oldPath);
      
      final cleanName = _cleanFileName(name);
      final expectedExportPath = File(p.join(srcDir.path, 'Suppliers', cleanName, 'profileImage_$basename'));
      final newAssetPath = File(p.join(markoAssetsDir.path, 'supplier_${id}_$basename'));
      
      if (await expectedExportPath.exists()) {
        await expectedExportPath.copy(newAssetPath.path);
        tempDb.execute("UPDATE suppliers SET imagePath = ? WHERE id = ?", [newAssetPath.path, id]);
      }
    }

    tempDb.dispose();

    // 6. Execute Algebric Replacement of active DB
    final dbFile = File(p.join(appDocs.path, 'markogroup_erp.sqlite'));
    await tempDbFile.copy(dbFile.path);
    await tempDbFile.delete(); // Cleanup
  }
}
"""

content = re.sub(old_import, new_import, content, flags=re.DOTALL)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated import logic")
