with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

old_focus = '''        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
             // Safety: don't confirm sale if typing in barcode or notes
             final focused = FocusManager.instance.primaryFocus;
             if (focused != null && focused.context?.widget is EditableText) {
                 return KeyEventResult.ignored;
             }
             if (_activeSession.cart.isNotEmpty) {
                 _processSale();
                 return KeyEventResult.handled;
             }
          }
          return KeyEventResult.ignored;
        },'''

new_focus = '''        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
             // If barcode field is focused, let it handle the enter key
             if (_barcodeFocusNode.hasFocus) {
                 return KeyEventResult.ignored;
             }
             if (_activeSession.cart.isNotEmpty) {
                 _processSale();
                 return KeyEventResult.handled;
             }
          }
          return KeyEventResult.ignored;
        },'''

content = content.replace(old_focus, new_focus)

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
print("POS screen focus patched perfectly")
