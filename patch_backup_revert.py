import re

with open('lib/src/application/backup/backup_service.dart', 'r') as f:
    content = f.read()

# Remove permission_handler import
content = content.replace("import 'package:permission_handler/permission_handler.dart';\n", "")

# Revert importData
old_import = """  Future<void> importData() async {
    if (Platform.isAndroid) {
      final statusManage = await Permission.manageExternalStorage.request();
      final statusStorage = await Permission.storage.request();
      if (!statusManage.isGranted && !statusStorage.isGranted) {
        throw Exception('Storage permissions are required to import data.');
      }
    }
    
    final srcDirStr = await FilePicker.getDirectoryPath(dialogTitle: 'Select Marko-Save folder to import');"""

new_import = """  Future<void> importData() async {
    final srcDirStr = await FilePicker.getDirectoryPath(dialogTitle: 'Select Marko-Save folder to import');"""

content = content.replace(old_import, new_import)

# Revert exportData
old_export = """  Future<void> exportData() async {
    if (Platform.isAndroid) {
      final statusManage = await Permission.manageExternalStorage.request();
      final statusStorage = await Permission.storage.request();
      if (!statusManage.isGranted && !statusStorage.isGranted) {
        throw Exception('Storage permissions are required to export data.');
      }
    }
    
    final destDirStr = await FilePicker.getDirectoryPath(dialogTitle: 'Select destination folder for Marko-Save');"""

new_export = """  Future<void> exportData() async {
    final destDirStr = await FilePicker.getDirectoryPath(dialogTitle: 'Select destination folder for Marko-Save');"""

content = content.replace(old_export, new_export)

# Ensure the exception string is updated to reflect SAF bypass logic (to be added)
content = content.replace(
    "throw Exception('OS Permission Denied (errno = 13). Even with permissions, Android blocks this path. Please move the Marko-Save folder to the root of Downloads or Documents, or grant All Files Access in Android Settings.');",
    "throw Exception('OS Permission Denied (errno = 13). Please compress the Marko-Save folder into a .zip file and select the zip file instead, or select the .sqlite file directly.');"
)


with open('lib/src/application/backup/backup_service.dart', 'w') as f:
    f.write(content)
