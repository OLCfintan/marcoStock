with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

focus_str = '''      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
             if (_activeSession.cart.isNotEmpty) {
                 _processSale();
                 return KeyEventResult.handled;
             }
          }
          return KeyEventResult.ignored;
        },
        child: LayoutBuilder(
'''

content = content.replace('      body: LayoutBuilder(\n', focus_str)

# The end of Scaffold is around the end of the file. Let's find "      ),\n    );\n  }\n}"
import re
content = re.sub(r'      \),\n    \);\n  \}\n\}', '      ),\n      ),\n    );\n  }\n}', content)

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
print("POS screen patched for Enter key correctly")
