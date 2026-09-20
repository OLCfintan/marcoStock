import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("return Card(", "return Card(\n                    key: ValueKey(p.id),")

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("return Card(", "return Card(\n                    key: ValueKey(p.id),")

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
