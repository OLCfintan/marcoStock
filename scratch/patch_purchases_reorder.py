import re

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

content = re.sub(
    r'ReorderableGridView\.builder\(\s*padding:',
    r'ReorderableGridView.builder(\n          onReorder: (oldIndex, newIndex) async {\n            final p = products.removeAt(oldIndex);\n            products.insert(newIndex, p);\n            await ref.read(productRepositoryProvider).updateProductReorder(products);\n          },\n          padding:',
    content
)

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)

