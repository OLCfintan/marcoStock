import re

with open('lib/src/application/backup/backup_service.dart', 'r') as f:
    content = f.read()

content = content.replace("FilePicker.platform?.pickFiles( /* to prevent error if it doesn't exist? No */", "FilePicker.platform.pickFiles(")
content = content.replace("await FilePicker.platform.pickFiles(", "await FilePicker.platform.pickFiles(") # reset it
# Actually, FilePicker.platform is a getter on FilePicker. Wait, no. file_picker 13+ requires FilePicker.platform.pickFiles
# I will just write exactly what it should be.
