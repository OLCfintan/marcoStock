import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

content = content.replace('p.unitSize?.toInt()', 'p.unitSize?.toDouble().toInt()')

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
