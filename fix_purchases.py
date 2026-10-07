import re

with open("lib/src/presentation/purchases/purchases_screen.dart", "r") as f:
    content = f.read()

old_state = "  PurchaseSession get _activeSession => _sessions[_activeSessionIndex];"
new_state = """  PurchaseSession get _activeSession => _sessions[_activeSessionIndex];
  final FocusNode _paymentFocusNode = FocusNode();
  final FocusNode _barcodeFocusNode = FocusNode();
  final FocusNode _supplierFocusNode = FocusNode();"""
content = content.replace(old_state, new_state)

old_dispose = """  @override
  void dispose() {
    super.dispose();
  }"""
new_dispose = """  @override
  void dispose() {
    _paymentFocusNode.dispose();
    _barcodeFocusNode.dispose();
    _supplierFocusNode.dispose();
    super.dispose();
  }"""
if old_dispose in content:
    content = content.replace(old_dispose, new_dispose)
else:
    # Just insert it before void dispose() if it has one, or after initState
    old_init = """      );
    }
  }"""
    new_init = """      );
    }
  }

  @override
  void dispose() {
    _paymentFocusNode.dispose();
    _barcodeFocusNode.dispose();
    _supplierFocusNode.dispose();
    super.dispose();
  }"""
    content = content.replace(old_init, new_init)

# Now in build:
if "shortcuts_provider.dart" not in content:
    content = content.replace("import '../../application/purchases/purchase_service.dart';", "import '../../application/purchases/purchase_service.dart';\nimport '../../application/system/shortcuts_provider.dart';\nimport 'package:flutter/services.dart';")

old_build = """  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);"""

new_build = """  Widget build(BuildContext context) {
    ref.listen(newPurchaseCartTriggerProvider, (prev, next) {
      if (next > (prev ?? 0)) {
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

    final productsAsync = ref.watch(productsStreamProvider);"""
content = content.replace(old_build, new_build)

old_scaffold = """    return Scaffold("""
new_scaffold = """    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          _barcodeFocusNode.requestFocus();
        },
        SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
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
        },
        SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
          _paymentFocusNode.requestFocus();
        },
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
            if (_barcodeFocusNode.hasFocus) return KeyEventResult.ignored;
            if (_activeSession.cart.isNotEmpty) {
              _confirmPurchase();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold("""
content = content.replace(old_scaffold, new_scaffold)

# Need to replace the end of build
content = re.sub(r'(\s*\);\n\s*\}\n\s*class _PaymentEntry)', r'\n      ),\n    ),\n    );\n  }\n\nclass _PaymentEntry', content)

# Link focus nodes to fields
# _paymentFocusNode -> to the payment TextField
old_payment_field = """                                                  controller: p.amountController,"""
new_payment_field = """                                                  focusNode: idx == 0 ? _paymentFocusNode : null,
                                                  controller: p.amountController,"""
content = content.replace(old_payment_field, new_payment_field)

old_amount_label = """                                                    labelText: 'Amount',"""
new_amount_label = """                                                    labelText: 'Amount',
                                                    border: InputBorder.none,"""
content = content.replace(old_amount_label, new_amount_label)

with open("lib/src/presentation/purchases/purchases_screen.dart", "w") as f:
    f.write(content)
print("Done purchases")
