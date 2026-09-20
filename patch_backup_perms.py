import re

with open('lib/src/application/backup/backup_service.dart', 'r') as f:
    content = f.read()

# Add permission_handler import
if "import 'package:permission_handler/permission_handler.dart';" not in content:
    content = "import 'package:permission_handler/permission_handler.dart';\n" + content
    
old_import = """  Future<void> importData() async {
    final srcDirStr = await FilePicker.getDirectoryPath(dialogTitle: 'Select Marko-Save folder to import');"""

new_import = """  Future<void> importData() async {
    if (Platform.isAndroid) {
      final statusManage = await Permission.manageExternalStorage.request();
      final statusStorage = await Permission.storage.request();
      if (!statusManage.isGranted && !statusStorage.isGranted) {
        throw Exception('Storage permissions are required to import data.');
      }
    }
    
    final srcDirStr = await FilePicker.getDirectoryPath(dialogTitle: 'Select Marko-Save folder to import');"""

content = content.replace(old_import, new_import)


old_export = """  Future<void> exportData() async {
    final destDirStr = await FilePicker.getDirectoryPath(dialogTitle: 'Select destination folder for Marko-Save');"""

new_export = """  Future<void> exportData() async {
    if (Platform.isAndroid) {
      final statusManage = await Permission.manageExternalStorage.request();
      final statusStorage = await Permission.storage.request();
      if (!statusManage.isGranted && !statusStorage.isGranted) {
        throw Exception('Storage permissions are required to export data.');
      }
    }
    
    final destDirStr = await FilePicker.getDirectoryPath(dialogTitle: 'Select destination folder for Marko-Save');"""

content = content.replace(old_export, new_export)

# Replace the throw Exception with a more informative message if it still fails
content = content.replace(
    "throw Exception('Permission Denied by Android Security. Please MOVE the Marko-Save folder out of WhatsApp into your main Downloads or Documents folder, and try importing it from there.');",
    "throw Exception('OS Permission Denied (errno = 13). Even with permissions, Android blocks this path. Please move the Marko-Save folder to the root of Downloads or Documents, or grant All Files Access in Android Settings.');"
)

with open('lib/src/application/backup/backup_service.dart', 'w') as f:
    f.write(content)
