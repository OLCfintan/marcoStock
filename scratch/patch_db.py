import re

with open('lib/src/infrastructure/database/tables/sales.dart', 'r') as f:
    content = f.read()

# Add companyBranch to Invoices
content = content.replace("TextColumn get paymentMethod => text().nullable()();", 
                          "TextColumn get paymentMethod => text().nullable()();\n  TextColumn get companyBranch => text().nullable().withDefault(const Constant('MARKO_GROUP'))(); // 'MARKO_GROUP' or 'MARKO_PEINT'")

with open('lib/src/infrastructure/database/tables/sales.dart', 'w') as f:
    f.write(content)

with open('lib/src/infrastructure/database/app_database.dart', 'r') as f:
    content = f.read()

content = content.replace("int get schemaVersion => 22;", "int get schemaVersion => 23;")
content = content.replace("      onUpgrade: (Migrator m, int from, int to) async {", 
                          "      onUpgrade: (Migrator m, int from, int to) async {\n        if (from < 23) {\n          await m.addColumn(invoices, invoices.companyBranch);\n        }")

with open('lib/src/infrastructure/database/app_database.dart', 'w') as f:
    f.write(content)

print("DB patched")
