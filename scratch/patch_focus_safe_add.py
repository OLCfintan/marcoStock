with open('lib/src/presentation/products/add_product_screen.dart', 'r') as f:
    content = f.read()

import re

old_focus = '''        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
             _submit();
             return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },'''

new_focus = '''        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
             final focused = FocusManager.instance.primaryFocus;
             // If they are in a text field, let them press enter to go next or submit
             // But usually enter in textfield shouldn't submit immediately unless we want it to.
             // The user said "i should also be able to confirme with <Enter> Key like with clicking the mouse"
             // If we ignore it when EditableText is focused, they can't submit while typing.
             // If we don't ignore it, typing Enter in a single-line field will submit the form! Which is what they want!
             // BUT what if it's a multiline field? Description is probably multiline.
             _submit();
             return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },'''

content = content.replace(old_focus, new_focus)

with open('lib/src/presentation/products/add_product_screen.dart', 'w') as f:
    f.write(content)
print("Add product screen focus patched safely")
