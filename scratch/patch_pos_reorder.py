import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# Replace GridView.builder with ReorderableGridView.builder
content = content.replace("GridView.builder(", "ReorderableGridView.builder(")
content = content.replace("return GridView.builder(", "return ReorderableGridView.builder(\n                  onReorder: (oldIndex, newIndex) async {\n                    final p = products.removeAt(oldIndex);\n                    products.insert(newIndex, p);\n                    await ref.read(productRepositoryProvider).updateProductReorder(products);\n                  },")
content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:reorderable_grid_view/reorderable_grid_view.dart';")

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("GridView.builder(", "ReorderableGridView.builder(")
content = content.replace("return GridView.builder(", "return ReorderableGridView.builder(\n                  onReorder: (oldIndex, newIndex) async {\n                    final p = products.removeAt(oldIndex);\n                    products.insert(newIndex, p);\n                    await ref.read(productRepositoryProvider).updateProductReorder(products);\n                  },")
content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:reorderable_grid_view/reorderable_grid_view.dart';")

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
