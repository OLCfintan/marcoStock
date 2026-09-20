import re

with open('lib/src/application/backup/backup_service.dart', 'r') as f:
    content = f.read()

old_code = """    // 1. Copy backup to a temporary file so we can safely mutate image paths BEFORE overwriting active DB
    final tempDbFile = File(p.join(appDocs.path, 'temp_restore.sqlite'));
    await systemBackup.copy(tempDbFile.path);"""

new_code = """    // 1. Copy backup to a temporary file so we can safely mutate image paths BEFORE overwriting active DB
    final tempDbFile = File(p.join(appDocs.path, 'temp_restore.sqlite'));
    try {
      final bytes = await systemBackup.readAsBytes();
      await tempDbFile.writeAsBytes(bytes, flush: true);
    } catch (e) {
      if (e.toString().contains('Permission denied')) {
        throw Exception('Permission Denied by Android Security. Please MOVE the Marko-Save folder out of WhatsApp into your main Downloads or Documents folder, and try importing it from there.');
      }
      throw Exception('Failed to read backup: $e');
    }"""

content = content.replace(old_code, new_code)

with open('lib/src/application/backup/backup_service.dart', 'w') as f:
    f.write(content)
