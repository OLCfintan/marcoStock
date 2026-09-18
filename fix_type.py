import re

filepath = "lib/src/presentation/purchases/purchases_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace(".firstOrNull?.name,", ".firstOrNull,")

with open(filepath, 'w') as f:
    f.write(content)
print("Fixed type error")
