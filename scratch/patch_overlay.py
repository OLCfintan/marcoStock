import re

with open('lib/src/presentation/widgets/app_idle_wrapper.dart', 'r') as f:
    content = f.read()

old_stack = """          if (_isScreensaverActive)
            Positioned.fill(
              child: ScreensaverScreen(
                onUnlock: () {
                  setState(() {
                    _isScreensaverActive = false;
                  });
                  _resetTimer();
                },
                correctPassword: 'admin', // Hardcoded admin lock for now
              ),
            ),"""

new_stack = """          if (_isScreensaverActive)
            Positioned.fill(
              child: Navigator(
                onGenerateRoute: (settings) => PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return ScreensaverScreen(
                      onUnlock: () {
                        setState(() {
                          _isScreensaverActive = false;
                        });
                        _resetTimer();
                      },
                      correctPassword: 'admin', // Hardcoded admin lock for now
                    );
                  },
                ),
              ),
            ),"""

content = content.replace(old_stack, new_stack)

with open('lib/src/presentation/widgets/app_idle_wrapper.dart', 'w') as f:
    f.write(content)
print("Overlay added to AppIdleWrapper.")
