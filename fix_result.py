import re

with open('lib/src/application/backup/backup_service.dart', 'r') as f:
    content = f.read()

# Fix result check
content = content.replace("if (result == null || result.files.isEmpty) return;", "if (result == null || result.isEmpty) return;")
content = content.replace("final pickedPath = result.files.single.path!;", "final pickedPath = result.first.path!;")

with open('lib/src/application/backup/backup_service.dart', 'w') as f:
    f.write(content)
