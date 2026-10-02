import re

with open('lib/src/infrastructure/database/app_database.dart', 'r') as f:
    content = f.read()

# Change schemaVersion
content = content.replace("int get schemaVersion => 21;", "int get schemaVersion => 22;")

# Add migration
new_migration = """      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 22) {
          await m.addColumn(invoices, invoices.paymentMethod);
        }
        if (from < 21) {"""
content = content.replace("      onUpgrade: (Migrator m, int from, int to) async {\n        if (from < 21) {", new_migration)

with open('lib/src/infrastructure/database/app_database.dart', 'w') as f:
    f.write(content)
print("Updated app_database.dart schema version.")
