import re

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

filter_logic = """
        var products = familyBases.values.toList();
        
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          final aq = ArabicTransliterator.transliterate(_searchQuery);
          products = products.where((p) {
            return p.name.toLowerCase().contains(q) ||
                   p.name.contains(aq) ||
                   p.reference.toLowerCase().contains(q);
          }).toList();
        }
"""
content = content.replace("final products = familyBases.values.toList();", filter_logic)

search_bar = """
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TextField(
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)?.searchStr ?? 'Search...',
                              prefixIcon: const Icon(Icons.search),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ),
                        Expanded(
"""
content = content.replace("Expanded(\n                          child: ReorderableGridView.builder(", search_bar + "                          child: ReorderableGridView.builder(")

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
