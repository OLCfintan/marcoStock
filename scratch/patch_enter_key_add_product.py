with open('lib/src/presentation/products/add_product_screen.dart', 'r') as f:
    content = f.read()

import_str = "import 'package:flutter/services.dart';\n"
if 'package:flutter/services.dart' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_str)

focus_str = '''      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
             _submit();
             return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Form(
'''

content = content.replace('      body: Form(\n', focus_str)

import re
content = re.sub(r'        \),\n      \),\n    \);\n  \}\n\n  Widget _buildSectionHeader', '        ),\n      ),\n      ),\n    );\n  }\n\n  Widget _buildSectionHeader', content)

with open('lib/src/presentation/products/add_product_screen.dart', 'w') as f:
    f.write(content)
print("Add product screen patched for Enter key correctly")
