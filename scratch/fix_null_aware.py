import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

content = content.replace('p.unitSize?.toDouble().toInt()', 'p.unitSize.toDouble().toInt()')
content = content.replace('addQty = p.unitSize.toDouble().toInt() ?? 1', 'addQty = p.unitSize.toDouble().toInt()')

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
