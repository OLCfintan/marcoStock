import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# Replace FAB
old_fab = """      floatingActionButton: _multiSelectedProductIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                final allProducts = productsAsync.valueOrNull ?? [];
                _addMultiSelectedToCart(allProducts);
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('${AppLocalizations.of(context)!.addBtn} ${_multiSelectedProductIds.length}'),
            )
          : null,"""

new_fab = """      floatingActionButton: _multiSelectedProductIds.isNotEmpty
          ? InkWell(
              onTap: () {
                final allProducts = productsAsync.valueOrNull ?? [];
                _addMultiSelectedToCart(allProducts);
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(colors: [Colors.orange, Colors.green]),
                  boxShadow: [
                    BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, spreadRadius: 2),
                    BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 8, spreadRadius: 2),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_shopping_cart, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('${AppLocalizations.of(context)!.addBtn} ${_multiSelectedProductIds.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          : null,"""

content = content.replace(old_fab, new_fab)

# Replace Checkbox
old_check = """                            child: Checkbox(
                              value: isSelected,
                              onChanged: (bool? val) {
                                setState(() {
                                  if (val == true) _multiSelectedProductIds.add(p.id);
                                  else _multiSelectedProductIds.remove(p.id);
                                });
                              },
                            ),"""

new_check = """                            child: Checkbox(
                              activeColor: Colors.orange,
                              checkColor: Colors.green,
                              fillColor: MaterialStateProperty.resolveWith((states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.orange;
                                }
                                return null;
                              }),
                              value: isSelected,
                              onChanged: (bool? val) {
                                setState(() {
                                  if (val == true) _multiSelectedProductIds.add(p.id);
                                  else _multiSelectedProductIds.remove(p.id);
                                });
                              },
                            ),"""

content = content.replace(old_check, new_check)

# Replace Selected Border
old_border = """                    shape: isSelected 
                        ? RoundedRectangleBorder(
                            side: BorderSide(color: theme.colorScheme.primary, width: 3),
                            borderRadius: BorderRadius.circular(12))
                        : null,"""

new_border = """                    shape: isSelected 
                        ? RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.orange, width: 3),
                            borderRadius: BorderRadius.circular(12))
                        : null,"""

content = content.replace(old_border, new_border)

# We also need to fix _showAutoInvoiceDialog in case python patch didn't work. Oh wait, it did work.

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
print('UI Patched.')
