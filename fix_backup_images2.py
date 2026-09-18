import re

filepath = "lib/src/application/backup/backup_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace("FilePicker.platform.getDirectoryPath", "FilePicker.getDirectoryPath")

with open(filepath, 'w') as f:
    f.write(content)
print("Updated import logic")
