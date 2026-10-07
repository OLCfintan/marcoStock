import re

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Add focus node and search state
    if '_searchFocusNode' not in content:
        if '_paymentFocusNode' in content:
            content = content.replace('final FocusNode _paymentFocusNode = FocusNode();', 'final FocusNode _paymentFocusNode = FocusNode();\n  final FocusNode _searchFocusNode = FocusNode();\n  String _searchQuery = \'\';')
        elif '_supplierFocusNode' in content:
            content = content.replace('final FocusNode _supplierFocusNode = FocusNode();', 'final FocusNode _supplierFocusNode = FocusNode();\n  final FocusNode _searchFocusNode = FocusNode();\n  String _searchQuery = \'\';')

    if '_searchFocusNode.dispose();' not in content:
        content = content.replace('super.dispose();', '_searchFocusNode.dispose();\n    super.dispose();')

    # Fix Ctrl+F binding
    content = content.replace('_barcodeFocusNode.requestFocus();', '_searchFocusNode.requestFocus();')
    
    # Add search logic before FocusTraversalGroup
    if 'var products = allProducts' not in content:
        content = content.replace('final products = allProducts.where((p) => p.isActive).toList();', 'var products = allProducts.where((p) => p.isActive).toList();\n                if (_searchQuery.isNotEmpty) {\n                  final q = _searchQuery.toLowerCase();\n                  products = products.where((p) => p.name.toLowerCase().contains(q) || p.reference.toLowerCase().contains(q)).toList();\n                }')
        
        # Replace return FocusTraversalGroup( with return Column(children: [ Padding(...) , Expanded(child: FocusTraversalGroup(
        target = 'return FocusTraversalGroup('
        replacement = '''return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        focusNode: _searchFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Search Products (Ctrl+F)',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                      ),
                    ),
                    Expanded(
                      child: FocusTraversalGroup('''
        content = content.replace(target, replacement)
        
        # We need to close the Expanded and Column where FocusTraversalGroup was closed.
        # Find the end of productsAsync.when( data: (allProducts) { ... } )
        # Let's just find the `);` that closes FocusTraversalGroup and replace it.
        # It's followed by `loading: () =>` 
        target2 = '''                );
              },
              loading: () =>'''
        replacement2 = '''                ),
                    ),
                  ],
                );
              },
              loading: () =>'''
        content = content.replace(target2, replacement2)

    with open(filepath, 'w') as f:
        f.write(content)

fix_file('lib/src/presentation/sales/pos_screen.dart')
fix_file('lib/src/presentation/purchases/purchases_screen.dart')
