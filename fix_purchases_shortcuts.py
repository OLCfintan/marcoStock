import re

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

# 1. Add focus nodes and search query
focus_nodes = """
  final FocusNode _supplierFocusNode = FocusNode();
  final FocusNode _paymentFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
"""
content = content.replace("final TextEditingController _barcodeController = TextEditingController();",
                          "final TextEditingController _barcodeController = TextEditingController();\n" + focus_nodes)

# 2. Add dispose logic
dispose_logic = """
    _supplierFocusNode.dispose();
    _paymentFocusNode.dispose();
    _searchFocusNode.dispose();
"""
content = content.replace("super.dispose();", dispose_logic + "    super.dispose();")

# 3. Add CallbackShortcuts inside build
shortcuts = """
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          _searchFocusNode.requestFocus();
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
        child: Scaffold(
"""
content = content.replace("return Scaffold(", shortcuts)
content = content.replace("      ),\n    );", "      ),\n    ),\n    );") # Close Focus and CallbackShortcuts at the very end of build

# 4. Attach _supplierFocusNode to AutocompleteSearchField for supplier
content = content.replace("AutocompleteSearchField<SupplierEntity>(", "AutocompleteSearchField<SupplierEntity>(\n                            focusNode: _supplierFocusNode,")

# 5. Attach _paymentFocusNode to the first payment amount field
content = content.replace("controller: p.amountController,", "controller: p.amountController,\n                                                  focusNode: idx == 0 ? _paymentFocusNode : null,")

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
