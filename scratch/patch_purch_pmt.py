import sys

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

target = """                            child: TextField(
                              controller: p.amountController,
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixIcon: Icon(Icons.attach_money, size: 16),
                                border: InputBorder.none,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (val) => setState(() {}),
                            ),"""

replacement = """                            child: TextField(
                              controller: p.amountController,
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixIcon: Icon(Icons.attach_money, size: 16),
                                border: InputBorder.none,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (val) => setState(() {}),
                              onSubmitted: (_) => _confirmPurchase(),
                            ),"""

if target in content:
    content = content.replace(target, replacement)
    with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
        f.write(content)
    print("Success")
else:
    print("Target not found")
