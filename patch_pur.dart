import 'dart:io';

void main() {
  var file = File('lib/src/presentation/purchases/purchases_screen.dart');
  var content = file.readAsStringSync();
  
  // Add _searchQuery and _searchFocusNode
  content = content.replaceFirst(
    '  final FocusNode _supplierFocusNode = FocusNode();',
    '  final FocusNode _supplierFocusNode = FocusNode();\n  final FocusNode _searchFocusNode = FocusNode();\n  String _searchQuery = \'\';'
  );
  
  // Dispose _searchFocusNode
  content = content.replaceFirst(
    '    super.dispose();',
    '    _searchFocusNode.dispose();\n    super.dispose();'
  );
  
  // Change Ctrl+F to use _searchFocusNode
  content = content.replaceFirst(
    '        SingleActivator(LogicalKeyboardKey.keyF, control: true): () {\n          _barcodeFocusNode.requestFocus();\n        },',
    '        SingleActivator(LogicalKeyboardKey.keyF, control: true): () {\n          _searchFocusNode.requestFocus();\n        },'
  );
  // wait purchases might not have barcodeFocusNode?
  
  // Add Search Bar and filter logic
  content = content.replaceFirst(
    '                final products = allProducts.where((p) => p.isActive).toList();',
    '                var products = allProducts.where((p) => p.isActive).toList();\n                if (_searchQuery.isNotEmpty) {\n                  final q = _searchQuery.toLowerCase();\n                  products = products.where((p) => p.name.toLowerCase().contains(q) || p.reference.toLowerCase().contains(q)).toList();\n                }'
  );
  
  content = content.replaceFirst(
    '                return FocusTraversalGroup(\n                  child: ReorderableGridView.builder(',
    '                return Column(\n                  children: [\n                    Padding(\n                      padding: const EdgeInsets.all(8.0),\n                      child: TextField(\n                        focusNode: _searchFocusNode,\n                        decoration: const InputDecoration(\n                          labelText: \'Search Products (Ctrl+F)\',\n                          prefixIcon: Icon(Icons.search),\n                          border: OutlineInputBorder(),\n                        ),\n                        onChanged: (val) {\n                          setState(() => _searchQuery = val);\n                        },\n                      ),\n                    ),\n                    Expanded(\n                      child: FocusTraversalGroup(\n                        child: ReorderableGridView.builder('
  );
  
  file.writeAsStringSync(content);
}
