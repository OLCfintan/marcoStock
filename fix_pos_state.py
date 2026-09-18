import re

filepath = "lib/src/presentation/sales/pos_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Add globals
globals_code = """
final List<PosSession> globalPosSessions = [];
int globalPosActiveSessionIndex = 0;

class PosScreen extends ConsumerStatefulWidget {
"""
content = content.replace("class PosScreen extends ConsumerStatefulWidget {", globals_code)

# Replace local fields
local_fields = r"""  final List<PosSession> _sessions = \[\];
  int _activeSessionIndex = 0;"""
global_fields = r"""  List<PosSession> get _sessions => globalPosSessions;
  int get _activeSessionIndex => globalPosActiveSessionIndex;
  set _activeSessionIndex(int val) => globalPosActiveSessionIndex = val;"""
content = re.sub(local_fields, global_fields, content)

# Fix initState
old_init = r"""  void initState\(\) \{
    super.initState\(\);
    _sessions.add\(PosSession\(id: DateTime.now\(\).millisecondsSinceEpoch.toString\(\), title: 'Cart 1'\)\);
  \}"""
new_init = r"""  void initState() {
    super.initState();
    if (globalPosSessions.isEmpty) {
      globalPosSessions.add(PosSession(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Cart 1'));
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
print("Updated PosScreen state")
