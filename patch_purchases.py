import sys

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

# 1. Add import
if 'shortcuts_provider.dart' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../application/system/shortcuts_provider.dart';")

# 2. Add FocusNodes
if '_paymentFocusNode' not in content:
    content = content.replace('class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {', 'class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {\n  final FocusNode _paymentFocusNode = FocusNode();\n  final FocusNode _supplierFocusNode = FocusNode();')

# 3. Dispose FocusNodes
if '_paymentFocusNode.dispose()' not in content:
    content = content.replace('    super.dispose();\n  }\n\n  void _addMultiSelectedToCart(List<Product> allProducts) {', '    _paymentFocusNode.dispose();\n    _supplierFocusNode.dispose();\n    super.dispose();\n  }\n\n  void _addMultiSelectedToCart(List<Product> allProducts) {')

# 4. Attach _supplierFocusNode
if 'focusNode: _supplierFocusNode' not in content:
    content = content.replace('                    key: ValueKey(_activeSession.id),', '                    key: ValueKey(_activeSession.id),\n                    focusNode: _supplierFocusNode,')

# 5. Attach _paymentFocusNode
if 'focusNode: idx == 0 ? _paymentFocusNode : null' not in content:
    content = content.replace('                                controller: p.amountController,', '                                controller: p.amountController,\n                                focusNode: idx == 0 ? _paymentFocusNode : null,')

# 6. Listen to newPurchaseCartTriggerProvider
if 'ref.listen(newPurchaseCartTriggerProvider' not in content:
    build_start = '  Widget build(BuildContext context) {'
    listen_code = '''
    ref.listen(newPurchaseCartTriggerProvider, (previous, next) {
      if (next > (previous ?? 0)) {
        setState(() {
          _sessions.add(
            PurchaseSession(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Cart ${_sessions.length + 1}',
            ),
          );
          _activeSessionIndex = _sessions.length - 1;
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          _supplierFocusNode.requestFocus();
        });
      }
    });
'''
    content = content.replace(build_start, build_start + listen_code)

# 7. Wrap Scaffold with CallbackShortcuts
if 'CallbackShortcuts' not in content:
    content = content.replace('    return Scaffold(', '''    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
          _paymentFocusNode.requestFocus();
        },
      },
      child: Scaffold(''')
    # find the last closing bracket of Scaffold which is at the end of build method
    content = content.replace('    );\n  }\n}\n\nclass PurchaseSession {', '    );\n    );\n  }\n}\n\nclass PurchaseSession {')

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
