import re

filepath = "lib/src/application/backup/backup_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace("import '../../infrastructure/database/app_database.dart';", "import '../../infrastructure/database/app_database.dart';\nimport '../../infrastructure/database/providers.dart';")

with open(filepath, 'w') as f:
    f.write(content)
print("done")
