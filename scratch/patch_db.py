import re

with open('lib/src/infrastructure/database/tables/products.dart', 'r') as f:
    content = f.read()

# Add displayOrder column
if 'IntColumn get displayOrder => integer().withDefault(const Constant(0))();' not in content:
    content = content.replace('BoolColumn get isActive => boolean().withDefault(const Constant(true))();', 'BoolColumn get isActive => boolean().withDefault(const Constant(true))();\n  IntColumn get displayOrder => integer().withDefault(const Constant(0))();')

with open('lib/src/infrastructure/database/tables/products.dart', 'w') as f:
    f.write(content)

with open('lib/src/infrastructure/database/app_database.dart', 'r') as f:
    content = f.read()

# Bump schema version
version_match = re.search(r'int get schemaVersion => (\d+);', content)
if version_match:
    old_version = version_match.group(1)
    new_version = str(int(old_version) + 1)
    content = content.replace(f'int get schemaVersion => {old_version};', f'int get schemaVersion => {new_version};')

# Add migration logic
migration_logic = """    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < """ + new_version + """) {
          await m.addColumn(products, products.displayOrder);
        }
      },
      onCreate: (Migrator m) async {"""
content = content.replace("    return MigrationStrategy(\n      onCreate: (Migrator m) async {", migration_logic)

with open('lib/src/infrastructure/database/app_database.dart', 'w') as f:
    f.write(content)

