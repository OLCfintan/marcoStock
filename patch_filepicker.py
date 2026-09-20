import re

with open('lib/src/application/backup/backup_service.dart', 'r') as f:
    content = f.read()

content = content.replace("FilePicker.platform.pickFiles(", "FilePicker.platform?.pickFiles( /* to prevent error if it doesn't exist? No */")
content = content.replace("await FilePicker.platform.pickFiles(", "await FilePicker.pickFiles(")

with open('lib/src/application/backup/backup_service.dart', 'w') as f:
    f.write(content)
