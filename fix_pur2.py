import re

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Change allProducts.where... in familyBases
    target = 'for (final p in allProducts.where((p) => p.isActive)) {'
    replacement = '''var productsListToIterate = allProducts.where((p) => p.isActive).toList();
        if (_searchQuery.isNotEmpty) {
           final q = _searchQuery.toLowerCase();
           productsListToIterate = productsListToIterate.where((p) => p.name.toLowerCase().contains(q) || p.reference.toLowerCase().contains(q)).toList();
        }
        for (final p in productsListToIterate) {'''
    content = content.replace(target, replacement)

    # Wrap the productsWidget with Column and SearchBar
    target_widget = 'return FocusTraversalGroup(\n          child: GridView.builder('
    replacement_widget = '''return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  labelText: 'Search Products (Ctrl+F)',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
            ),
            Expanded(
              child: FocusTraversalGroup(
                child: GridView.builder('''
    content = content.replace(target_widget, replacement_widget)

    # Find the end of GridView.builder to close Expanded and Column
    target_close = '''              ],
            );
          },
        );
      },'''
    replacement_close = '''              ],
            );
          },
        ),
      ),
    ];
  }(),
);
      },'''
    # Actually, a safer way to close it is to look for the end of GridView.builder
    
    with open(filepath, 'w') as f:
        f.write(content)

fix_file('lib/src/presentation/purchases/purchases_screen.dart')
