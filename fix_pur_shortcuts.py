import re

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Add Ctrl+F and Ctrl+P bindings
    if 'SingleActivator(LogicalKeyboardKey.keyF, control: true):' not in content:
        # Check where CallbackShortcuts is
        target = 'return CallbackShortcuts(\n      bindings: {'
        replacement = """return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          _searchFocusNode.requestFocus();
        },
        SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
          _paymentFocusNode.requestFocus();
        },"""
        if target in content:
            content = content.replace(target, replacement)
        else:
            # We need to wrap Scaffold in CallbackShortcuts
            scaffold_target = 'child: Scaffold('
            scaffold_replacement = """child: CallbackShortcuts(
        bindings: {
          SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
            _searchFocusNode.requestFocus();
          },
          SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
            _paymentFocusNode.requestFocus();
          },
        },
        child: Scaffold("""
            content = content.replace(scaffold_target, scaffold_replacement)
            # Find the closing parenthesis of Scaffold and close CallbackShortcuts.
            # Actually easier to just replace `return Focus(` with `return CallbackShortcuts( bindings: {...}, child: Focus(`
            if 'return Focus(' in content:
                content = content.replace('return Focus(', 'return CallbackShortcuts( bindings: { SingleActivator(LogicalKeyboardKey.keyF, control: true): () { _searchFocusNode.requestFocus(); }, SingleActivator(LogicalKeyboardKey.keyP, control: true): () { _paymentFocusNode.requestFocus(); }, }, child: Focus(')

    with open(filepath, 'w') as f:
        f.write(content)

fix_file('lib/src/presentation/purchases/purchases_screen.dart')
