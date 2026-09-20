import re

with open('lib/src/application/backup/backup_service.dart', 'r') as f:
    content = f.read()

if "import 'package:archive/archive_io.dart';" not in content:
    content = "import 'package:archive/archive_io.dart';\n" + content

old_import = """  Future<void> importData() async {
    final srcDirStr = await FilePicker.getDirectoryPath(dialogTitle: 'Select Marko-Save folder to import');
    if (srcDirStr == null) return;

    final srcDir = Directory(srcDirStr);
    final systemBackup = File(p.join(srcDir.path, 'system_backup.sqlite'));

    if (!await systemBackup.exists()) {
      throw Exception('Valid Marko-Save system_backup.sqlite not found in the selected folder!');
    }"""

new_import = """  Future<void> importData() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select system_backup.sqlite OR Marko-Save.zip',
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;

    final pickedPath = result.files.single.path!;
    final pickedFile = File(pickedPath);
    
    File systemBackup;
    Directory srcDir;
    
    if (pickedPath.toLowerCase().endsWith('.zip')) {
      final bytes = await pickedFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final tempDir = await getTemporaryDirectory();
      srcDir = Directory(p.join(tempDir.path, 'Marko-Save-Extracted'));
      if (await srcDir.exists()) await srcDir.delete(recursive: true);
      await srcDir.create();
      
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(p.join(srcDir.path, filename));
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(data);
        }
      }
      
      systemBackup = File(p.join(srcDir.path, 'system_backup.sqlite'));
      if (!await systemBackup.exists()) {
        systemBackup = File(p.join(srcDir.path, 'Marko-Save', 'system_backup.sqlite'));
        if (await systemBackup.exists()) {
          srcDir = Directory(p.join(srcDir.path, 'Marko-Save'));
        }
      }
    } else {
      systemBackup = pickedFile;
      srcDir = pickedFile.parent;
    }

    if (!await systemBackup.exists()) {
      throw Exception('Valid system_backup.sqlite not found in the selected file/folder!');
    }"""

content = content.replace(old_import, new_import)

with open('lib/src/application/backup/backup_service.dart', 'w') as f:
    f.write(content)
