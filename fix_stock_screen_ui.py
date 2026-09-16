import re

filepath = "lib/src/presentation/stock/stock_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

# I need to get the SI unit. I can copy the getSIUnit logic locally inside buildList or just map it.
old_ui = r"""                  title: Text\('\$\{item.productName\} \$\{item.unitSize\}\$\{item.unit\}'\),
                  subtitle: Text\('Ref: \$\{item.productReference\} \| Loc: \$\{item.locationName\}'\),
                  trailing: Text\(
                    '\$\{item.quantity.toStringAsFixed\(2\)\} Units',
                    style: const TextStyle\(fontWeight: FontWeight.bold, fontSize: 16\),
                  \),"""

new_ui = r"""                  title: Text('${item.productName} (Base Family)'),
                  subtitle: Text('Ref: ${item.productReference} | Loc: ${item.locationName}'),
                  trailing: Text(
                    '${item.quantity.toStringAsFixed(2)} ${() {
                      final u = item.unit.toLowerCase();
                      if (['ml', 'cl', 'dl', 'l'].contains(u)) return 'L';
                      if (['mg', 'g', 'kg', 't'].contains(u)) return 'KG';
                      if (u == 'm3') return 'M3';
                      return 'Units';
                    }()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),"""

content = re.sub(old_ui, new_ui, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated stock_screen.dart")
