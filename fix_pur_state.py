import re

filepath = "lib/src/presentation/purchases/purchases_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Add globals
globals_code = """
final List<PurchaseSession> globalPurchaseSessions = [];
int globalPurchaseActiveSessionIndex = 0;

class PurchasesScreen extends ConsumerStatefulWidget {
"""
content = content.replace("class PurchasesScreen extends ConsumerStatefulWidget {", globals_code)

# Replace local fields
local_fields = r"""  final List<PurchaseSession> _sessions = \[\];
  int _activeSessionIndex = 0;"""
global_fields = r"""  List<PurchaseSession> get _sessions => globalPurchaseSessions;
  int get _activeSessionIndex => globalPurchaseActiveSessionIndex;
  set _activeSessionIndex(int val) => globalPurchaseActiveSessionIndex = val;"""
content = re.sub(local_fields, global_fields, content)

# Fix initState
old_init = r"""  void initState\(\) \{
    super.initState\(\);
    _sessions.add\(PurchaseSession\(id: DateTime.now\(\).millisecondsSinceEpoch.toString\(\), title: 'Cart 1'\)\);
  \}"""
new_init = r"""  void initState() {
    super.initState();
    if (globalPurchaseSessions.isEmpty) {
      globalPurchaseSessions.add(PurchaseSession(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Cart 1'));
    }
  }"""
content = re.sub(old_init, new_init, content)

# Fix dispose
old_dispose = r"""  void dispose\(\) \{
    _barcodeController.dispose\(\);
    _barcodeFocusNode.dispose\(\);
    for \(var s in _sessions\) \{
      s.dispose\(\);
    \}
    super.dispose\(\);
  \}"""
new_dispose = r"""  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    // Do NOT dispose _sessions so they survive screen transitions!
    super.dispose();
  }"""
content = re.sub(old_dispose, new_dispose, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated PurchasesScreen state")
