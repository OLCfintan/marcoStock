import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("              return ReorderableGridView.builder(", "              return ReorderableGridView.builder(\n                onReorder: (oldIndex, newIndex) async {\n                  final p = products.removeAt(oldIndex);\n                  products.insert(newIndex, p);\n                  await ref.read(productRepositoryProvider).updateProductReorder(products);\n                },")

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("              return ReorderableGridView.builder(", "              return ReorderableGridView.builder(\n                onReorder: (oldIndex, newIndex) async {\n                  final p = products.removeAt(oldIndex);\n                  products.insert(newIndex, p);\n                  await ref.read(productRepositoryProvider).updateProductReorder(products);\n                },")

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
