import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

old_dialog = """  Future<void> _showAutoInvoiceDialog() async {
    final targetCtrl = TextEditingController();
    final familiesCtrl = TextEditingController(text: '3');
    final allProducts = ref.read(productsStreamProvider).valueOrNull ?? [];
    if (allProducts.isEmpty) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Auto Invoice Generator'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetCtrl,
              decoration: const InputDecoration(labelText: 'Target Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: familiesCtrl,
              decoration: const InputDecoration(labelText: 'Number of Families (Categories)'),
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

new_dialog = """  Future<void> _showAutoInvoiceDialog() async {
    final targetHtCtrl = TextEditingController();
    final targetTtcCtrl = TextEditingController();
    final familiesCtrl = TextEditingController(text: '3');
    final allProducts = ref.read(productsStreamProvider).valueOrNull ?? [];
    if (allProducts.isEmpty) return;
    
    targetHtCtrl.addListener(() {
      if (targetHtCtrl.text.isEmpty) return;
      if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
          final ht = double.tryParse(targetHtCtrl.text);
          if (ht != null) {
              final ttc = ht * 1.20;
              if (targetTtcCtrl.text != ttc.toStringAsFixed(2)) {
                  targetTtcCtrl.text = ttc.toStringAsFixed(2);
              }
          }
      }
    });
    
    targetTtcCtrl.addListener(() {
      if (targetTtcCtrl.text.isEmpty) return;
      if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
          final ttc = double.tryParse(targetTtcCtrl.text);
          if (ttc != null) {
              final ht = ttc / 1.20;
              if (targetHtCtrl.text != ht.toStringAsFixed(2)) {
                  targetHtCtrl.text = ht.toStringAsFixed(2);
              }
          }
      }
    });

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Auto Invoice Generator'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetHtCtrl,
              decoration: const InputDecoration(labelText: 'Target Amount (HT)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) {
                 final ht = double.tryParse(val) ?? 0.0;
                 targetTtcCtrl.text = (ht * 1.20).toStringAsFixed(2);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetTtcCtrl,
              decoration: const InputDecoration(labelText: 'Target Amount (TTC)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) {
                 final ttc = double.tryParse(val) ?? 0.0;
                 targetHtCtrl.text = (ttc / 1.20).toStringAsFixed(2);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: familiesCtrl,
              decoration: const InputDecoration(labelText: 'Number of Families (Categories)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () {
              final target = double.tryParse(targetHtCtrl.text) ?? 0.0;
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

if old_dialog in content:
    content = content.replace(old_dialog, new_dialog)
    print('Dialog patched.')
else:
    print('Dialog NOT patched.')

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
