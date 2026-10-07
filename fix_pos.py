with open("lib/src/presentation/sales/pos_screen.dart", "r") as f:
    content = f.read()

if "shortcuts_provider.dart" not in content:
    content = content.replace("import '../../application/sales/sales_service.dart';", "import '../../application/sales/sales_service.dart';\nimport '../../application/system/shortcuts_provider.dart';")

old_build = """  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);"""

new_build = """  Widget build(BuildContext context) {
    ref.listen(newSaleCartTriggerProvider, (prev, next) {
      if (next > (prev ?? 0)) {
        setState(() {
          _sessions.add(
            PosSession(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Cart ${_sessions.length + 1}',
            ),
          );
          _activeSessionIndex = _sessions.length - 1;
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          _clientFocusNode.requestFocus();
        });
      }
    });

    final productsAsync = ref.watch(productsStreamProvider);"""

content = content.replace(old_build, new_build)

with open("lib/src/presentation/sales/pos_screen.dart", "w") as f:
    f.write(content)
