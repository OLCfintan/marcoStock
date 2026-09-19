import re

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("import '../widgets/item_navigator.dart';", "import '../widgets/item_navigator.dart';\nimport '../widgets/quantity_selector_dialog.dart';")

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
