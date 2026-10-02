import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# Replace _showAutoInvoiceDialog
old_dialog = """  void _showAutoInvoiceDialog(BuildContext context, List<Product> allProducts) {
    final targetCtrl = TextEditingController();
    final familiesCtrl = TextEditingController(text: '3');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Auto Invoice Generator'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetCtrl,
              decoration: const InputDecoration(labelText: 'Target Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: familiesCtrl,
              decoration: const InputDecoration(labelText: 'Number of Families'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () {
              final target = double.tryParse(targetCtrl.text) ?? 0.0;
              final numFam = int.tryParse(familiesCtrl.text) ?? 1;
              if (target > 0 && numFam > 0) {
                Navigator.pop(ctx);
                _generateAutoInvoice(target, numFam, allProducts);
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }"""

new_dialog = """  void _showAutoInvoiceDialog(BuildContext context, List<Product> allProducts) {
    final targetCtrl = TextEditingController();
    final familiesCtrl = TextEditingController(text: '3');
    String targetType = 'TTC'; // default TTC
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Auto Invoice Generator'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: targetCtrl,
                  decoration: const InputDecoration(labelText: 'Target Amount'),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: 'HT',
                      groupValue: targetType,
                      onChanged: (v) => setState(() => targetType = v!),
                    ),
                    const Text('HT'),
                    Radio<String>(
                      value: 'TTC',
                      groupValue: targetType,
                      onChanged: (v) => setState(() => targetType = v!),
                    ),
                    const Text('TTC'),
                  ],
                ),
                TextField(
                  controller: familiesCtrl,
                  decoration: const InputDecoration(labelText: 'Number of Families'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
              TextButton(
                onPressed: () {
                  double target = double.tryParse(targetCtrl.text) ?? 0.0;
                  final numFam = int.tryParse(familiesCtrl.text) ?? 1;
                  if (target > 0 && numFam > 0) {
                    if (targetType == 'TTC') target = target / 1.20;
                    Navigator.pop(ctx);
                    _generateAutoInvoice(target, numFam, allProducts);
                  }
                },
                child: const Text('Generate'),
              ),
            ],
          );
        }
      ),
    );
  }"""

content = content.replace(old_dialog, new_dialog)

old_algo = """    Map<Product, int> selectedItems = {};
    double currentTotal = 0.0;
    
    final rand = Random();
    int attempts = 0;
    while (attempts < 5000) {
      if (pool.isEmpty) break;
      final p = pool[rand.nextInt(pool.length)];
      final price = p.sellingPrice.toDouble();
      
      if (currentTotal + price <= targetAmount * 1.05) {
        selectedItems[p] = (selectedItems[p] ?? 0) + 1;
        currentTotal += price;
      }
      
      if (currentTotal >= targetAmount * 0.95 && currentTotal <= targetAmount * 1.05) {
        break;
      }
      attempts++;
    }"""

new_algo = """    Map<Product, int> selectedItems = {};
    double currentTotal = 0.0;
    
    final rand = Random();
    int attempts = 0;
    while (attempts < 5000) {
      if (pool.isEmpty) break;
      final p = pool[rand.nextInt(pool.length)];
      final price = p.sellingPrice.toDouble();
      
      // Box Logic: if remaining >= 500, buy by unitSize (box). Else by unit (1).
      double remaining = targetAmount - currentTotal;
      int addQty = 1;
      if (remaining >= 500.0) {
          addQty = p.unitSize?.toInt() ?? 1;
          if (addQty < 1) addQty = 1;
          // If a box is extremely expensive (e.g. box of 1000 items), revert to 1 if it would overshoot drastically.
          if (price * addQty > remaining * 1.5) addQty = 1;
      }
      
      double cost = price * addQty;
      
      if (currentTotal + cost <= targetAmount * 1.05) {
        selectedItems[p] = (selectedItems[p] ?? 0) + addQty;
        currentTotal += cost;
      }
      
      if (currentTotal >= targetAmount * 0.95 && currentTotal <= targetAmount * 1.05) {
        break;
      }
      attempts++;
    }"""

content = content.replace(old_algo, new_algo)

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
print('Auto Invoice patched.')
