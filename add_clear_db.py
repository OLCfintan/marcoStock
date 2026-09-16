import re

filepath = "lib/src/infrastructure/database/app_database.dart"
with open(filepath, 'r') as f:
    content = f.read()

clear_func = """  Future<void> clearAllData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
      
      // Re-seed defaults
      await into(stockLocations).insert(StockLocationsCompanion.insert(
        id: 'BASE_WAREHOUSE_01',
        name: 'Main Warehouse',
        type: 'BASE',
      ));
      
      await into(stockLocations).insert(StockLocationsCompanion.insert(
        id: 'MAGAZIN_01',
        name: 'Client Magazin',
        type: 'MAGAZIN',
      ));
      
      await into(clients).insert(ClientsCompanion.insert(
        id: 'WALKIN_CLIENT_01',
        name: 'Client Passager',
        type: const Value('TEMP'),
        tier: const Value('Tier 1'),
      ));
    });
  }
"""

if "Future<void> clearAllData()" not in content:
    # Insert it right before @override int get schemaVersion
    content = content.replace("  @override\n  int get schemaVersion", clear_func + "\n  @override\n  int get schemaVersion")
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"Added clearAllData to {filepath}")
