import re

filepath = "lib/src/application/import/import_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_unit_logic = r"""              unit: drift\.Value\(\(\) \{
                final u = map\['UNIT'\] \?\? existingProduct\?\.unit \?\? 'Unit';
                return UnitConversionService\.allUnits\.contains\(u\) \? u : 
                  \(UnitConversionService\.allUnits\.contains\(u\.toLowerCase\(\)\) \? u\.toLowerCase\(\) : 
                  \(UnitConversionService\.allUnits\.contains\(u\.toUpperCase\(\)\) \? u\.toUpperCase\(\) : 'Unit'\)\);
              \}\(\)\),"""

new_unit_logic = r"""              unit: drift.Value(() {
                final u = map['UNIT'] ?? existingProduct?.unit ?? 'Unit';
                try {
                  return UnitConversionService.allUnits.firstWhere((e) => e.toLowerCase() == u.toLowerCase());
                } catch (_) {
                  return 'Unit';
                }
              }()),"""

content = re.sub(old_unit_logic, new_unit_logic, content)
with open(filepath, 'w') as f:
    f.write(content)
print("Updated unit matching")
