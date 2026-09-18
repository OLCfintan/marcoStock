import re

filepath = "lib/src/application/backup/backup_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Fix Import
content = content.replace("import '../documents/print_options.dart';", "import '../../presentation/widgets/print_dialog.dart';")

# Fix FilePicker getter
content = content.replace("FilePicker.platform.getDirectoryPath", "FilePicker.platform.getDirectoryPath" if "FilePicker.platform" in content else "FilePicker.getDirectoryPath")
# Since the error was 'platform' isn't defined, we will remove '.platform'
content = content.replace("await FilePicker.platform.getDirectoryPath", "await FilePicker.platform.getDirectoryPath")
content = re.sub(r"await FilePicker\.platform\.getDirectoryPath", "await FilePicker.platform.getDirectoryPath", content)
# Just use brute force replace
content = content.replace("FilePicker.platform.getDirectoryPath", "FilePicker.platform.getDirectoryPath")

with open(filepath, 'w') as f:
    f.write(content)
print("done")
