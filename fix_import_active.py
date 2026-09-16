import re

filepath = "lib/src/application/import/import_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old = r"""              packagingType: drift.Value\(\(\) \{
                 final p = map\['PACKAGING'\] \?\? existingProduct\?\.packagingType \?\? 'Unit';
                 final opts = \['Unit', 'Box', 'Ticket', 'Bottle'\];
                 return opts\.contains\(p\) \? p : \(opts\.map\(\(o\) => o\.toLowerCase\(\)\)\.contains\(p\.toLowerCase\(\)\) \? 
                        opts\.firstWhere\(\(o\) => o\.toLowerCase\(\) == p\.toLowerCase\(\)\) : 'Unit'\);
              \}\(\)\),
            \);"""

new = r"""              packagingType: drift.Value(() {
                 final p = map['PACKAGING'] ?? existingProduct?.packagingType ?? 'Unit';
                 final opts = ['Unit', 'Box', 'Ticket', 'Bottle'];
                 return opts.contains(p) ? p : (opts.map((o) => o.toLowerCase()).contains(p.toLowerCase()) ? 
                        opts.firstWhere((o) => o.toLowerCase() == p.toLowerCase()) : 'Unit');
              }()),
              isActive: const drift.Value(true),
            );"""

content = re.sub(old, new, content)
with open(filepath, 'w') as f:
    f.write(content)
print("Added isActive to import upsert")
