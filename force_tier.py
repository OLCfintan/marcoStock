import re

filepath = "lib/src/infrastructure/database/app_database.dart"
with open(filepath, 'r') as f:
    content = f.read()

# find beforeOpen: (details) async {
old_beforeOpen = r"""      beforeOpen: \(details\) async \{
        await customStatement\('PRAGMA foreign_keys = ON'\);"""

new_beforeOpen = r"""      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        // Force Client Passager to Tier 3 prices always
        await customStatement("UPDATE clients SET tier = 'Tier 3' WHERE id = 'WALKIN_CLIENT_01'");"""

content = re.sub(old_beforeOpen, new_beforeOpen, content, flags=re.MULTILINE)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
