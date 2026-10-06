import sys

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

target = """      body: LayoutBuilder("""

replacement = """      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
             if (_activeSession.cart.isNotEmpty) {
                 _confirmPurchase();
                 return KeyEventResult.handled;
             }
          }
          return KeyEventResult.ignored;
        },
        child: LayoutBuilder("""

if target in content:
    content = content.replace(target, replacement)
    # now append the closing parenthesis to the body
    content = content.replace("    ); // Scaffold", "      ),\n    ); // Scaffold")
    with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
        f.write(content)
    print("Success")
else:
    print("Target not found")
