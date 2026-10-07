import sys

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

target = '''        SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
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
        },'''

content = content.replace(target, '')

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
