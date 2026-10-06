import sys

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

target = """                                          builder: (ctx) => AlertDialog(
                                            title: Text("${AppLocalizations.of(context)!.edit} ${product.localizedName(loc)}"),
                                            content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextFormField(
                                            controller: qtyCtrl,
                                            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.quantity),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          ),
                                          TextFormField(
                                            controller: priceCtrl,
                                            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.unitPrice),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
                                        TextButton(
                                          onPressed: () {
                                            final newQty = Decimal.tryParse(qtyCtrl.text) ?? line.quantity;
                                            final newPrice = Decimal.tryParse(priceCtrl.text) ?? line.unitPrice;
                                            setState(() {
                                              if (newQty <= Decimal.zero) {
                                                _activeSession.cart.removeAt(index);
                                              } else {
                                                _activeSession.cart[index] = SaleLineRequest(
                                                  productId: product.id,
                                                  quantity: newQty,
                                                  unitPrice: newPrice,
                                                  discount: line.discount,
                                                );
                                              }
                                            });
                                            Navigator.pop(ctx);
                                          },
                                          child: Text(AppLocalizations.of(context)!.save),
                                        ),
                                      ]
                                    )"""

replacement = """                                          builder: (ctx) {
                                            void saveEdit() {
                                                final newQty = Decimal.tryParse(qtyCtrl.text) ?? line.quantity;
                                                final newPrice = Decimal.tryParse(priceCtrl.text) ?? line.unitPrice;
                                                setState(() {
                                                  if (newQty <= Decimal.zero) {
                                                    _activeSession.cart.removeAt(index);
                                                  } else {
                                                    _activeSession.cart[index] = SaleLineRequest(
                                                      productId: product.id,
                                                      quantity: newQty,
                                                      unitPrice: newPrice,
                                                      discount: line.discount,
                                                    );
                                                  }
                                                });
                                                Navigator.pop(ctx);
                                            }

                                            return AlertDialog(
                                            title: Text("${AppLocalizations.of(context)!.edit} ${product.localizedName(loc)}"),
                                            content: Focus(
                                              onKeyEvent: (node, event) {
                                                if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                                                  saveEdit();
                                                  return KeyEventResult.handled;
                                                }
                                                return KeyEventResult.ignored;
                                              },
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextFormField(
                                                    controller: qtyCtrl,
                                                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.quantity),
                                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                    onFieldSubmitted: (_) => saveEdit(),
                                                  ),
                                                  TextFormField(
                                                    controller: priceCtrl,
                                                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.unitPrice),
                                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                    onFieldSubmitted: (_) => saveEdit(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
                                              TextButton(
                                                onPressed: saveEdit,
                                                child: Text(AppLocalizations.of(context)!.save),
                                              ),
                                            ],
                                          );
                                          }"""

if target in content:
    content = content.replace(target, replacement)
    with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
        f.write(content)
    print("Success")
else:
    print("Target not found")
