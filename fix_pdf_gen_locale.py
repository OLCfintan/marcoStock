import re

filepath = "lib/src/application/documents/pdf_generator.dart"
with open(filepath, 'r') as f:
    content = f.read()

if "import 'dart:ui';" not in content:
    content = content.replace("import 'dart:io';", "import 'dart:io';\nimport 'dart:ui';")

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
