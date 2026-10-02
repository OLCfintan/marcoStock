import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# Change declaration
content = content.replace("Set<String> _multiSelectedProductIds = {};", "final ValueNotifier<Set<String>> _multiSelectedProductIds = ValueNotifier({});")

# Change _addMultiSelectedToCart
old_add_cart = """  Future<void> _addMultiSelectedToCart(List<Product> allProducts) async {
    if (_multiSelectedProductIds.isEmpty) return;
    
    final firstProductId = _multiSelectedProductIds.first;"""

new_add_cart = """  Future<void> _addMultiSelectedToCart(List<Product> allProducts) async {
    if (_multiSelectedProductIds.value.isEmpty) return;
    
    final firstProductId = _multiSelectedProductIds.value.first;"""

content = content.replace(old_add_cart, new_add_cart)

content = content.replace("for (final pid in _multiSelectedProductIds) {", "for (final pid in _multiSelectedProductIds.value) {")
content = content.replace("_multiSelectedProductIds.clear();", "_multiSelectedProductIds.value = {};")

# Change FAB
old_fab = """      floatingActionButton: _multiSelectedProductIds.isNotEmpty
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
                    BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2),
                    BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2),
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

new_fab = """      floatingActionButton: ValueListenableBuilder<Set<String>>(
        valueListenable: _multiSelectedProductIds,
        builder: (context, selectedIds, child) {
          return selectedIds.isNotEmpty
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
                        BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2),
                        BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_shopping_cart, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('${AppLocalizations.of(context)!.addBtn} ${selectedIds.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink();
        },
      ),"""

if old_fab in content:
    content = content.replace(old_fab, new_fab)
else:
    print('FAB NOT patched.')

# Regex to match the itemBuilder exactly to replace with ValueListenableBuilder
old_item = """                itemBuilder: (context, index) {
                  final p = products[index];
                  final isSelected = _multiSelectedProductIds.contains(p.id);
                  return Card(
                    key: ValueKey(p.id),
                    elevation: isSelected ? 8 : 2,
                    clipBehavior: Clip.antiAlias,
                    shape: isSelected 
                        ? RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.orange, width: 3),
                            borderRadius: BorderRadius.circular(12))
                        : null,
                    child: InkWell(
                      onTap: () {
                        if (_multiSelectedProductIds.isNotEmpty) {
                          setState(() {
                            if (isSelected) _multiSelectedProductIds.remove(p.id);
                            else _multiSelectedProductIds.add(p.id);
                          });
                        } else {
                          _addToCart(p);
                        }
                      },
                      onDoubleTap: () => ItemNavigator.openProduct(context, p),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [theme.colorScheme.primaryContainer, theme.colorScheme.surface],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(child: ProductImage(product: p, size: double.infinity)),
                                const SizedBox(height: 8),
                                Text(p.localizedLabel(loc), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${p.sellingPrice.toStringAsFixed(2)} Dhs', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Checkbox(
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },"""

new_item = """                itemBuilder: (context, index) {
                  final p = products[index];
                  return ValueListenableBuilder<Set<String>>(
                    key: ValueKey(p.id),
                    valueListenable: _multiSelectedProductIds,
                    builder: (context, selectedIds, child) {
                      final isSelected = selectedIds.contains(p.id);
                      return Card(
                        elevation: isSelected ? 8 : 2,
                        clipBehavior: Clip.antiAlias,
                        shape: isSelected 
                            ? RoundedRectangleBorder(
                                side: const BorderSide(color: Colors.orange, width: 3),
                                borderRadius: BorderRadius.circular(12))
                            : null,
                        child: InkWell(
                          onTap: () {
                            if (_multiSelectedProductIds.value.isNotEmpty) {
                                final newSet = Set<String>.from(_multiSelectedProductIds.value);
                                if (isSelected) newSet.remove(p.id);
                                else newSet.add(p.id);
                                _multiSelectedProductIds.value = newSet;
                            } else {
                              _addToCart(p);
                            }
                          },
                          onDoubleTap: () => ItemNavigator.openProduct(context, p),
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [theme.colorScheme.primaryContainer, theme.colorScheme.surface],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(child: ProductImage(product: p, size: double.infinity)),
                                    const SizedBox(height: 8),
                                    Text(p.localizedLabel(loc), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('${p.sellingPrice.toStringAsFixed(2)} Dhs', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Checkbox(
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
                                    final newSet = Set<String>.from(_multiSelectedProductIds.value);
                                    if (val == true) newSet.add(p.id);
                                    else newSet.remove(p.id);
                                    _multiSelectedProductIds.value = newSet;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },"""

if old_item in content:
    content = content.replace(old_item, new_item)
    print('Item builder patched.')
else:
    print('Item builder NOT patched.')

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)

