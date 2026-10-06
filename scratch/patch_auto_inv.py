import sys

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

target = """    await showDialog(
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
    );"""

replacement = """    await showDialog(
      context: context,
      builder: (ctx) {
        void submit() {
          final target = double.tryParse(targetHtCtrl.text) ?? 0.0;
          final numFam = int.tryParse(familiesCtrl.text) ?? 1;
          if (target > 0 && numFam > 0) {
            Navigator.pop(ctx);
            _generateAutoInvoice(target, numFam, allProducts);
          }
        }
        
        return AlertDialog(
          title: const Text('Auto Invoice Generator'),
          content: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                submit();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Column(
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
                  onSubmitted: (_) => submit(),
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
                  onSubmitted: (_) => submit(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: familiesCtrl,
                  decoration: const InputDecoration(labelText: 'Number of Families (Categories)'),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => submit(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
            TextButton(
              onPressed: submit,
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );"""

if target in content:
    content = content.replace(target, replacement)
    with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
        f.write(content)
    print("Success")
else:
    print("Target not found")
