import re

with open('lib/src/presentation/widgets/app_idle_wrapper.dart', 'r') as f:
    content = f.read()

# We need to inject `currentUserProvider` into `_AppIdleWrapperState`.
# We are inside a ConsumerState<AppIdleWrapper>
# Let's see how `ScreensaverScreen` is constructed.

old_screensaver = """                    return ScreensaverScreen(
                      onUnlock: () {
                        setState(() {
                          _isScreensaverActive = false;
                        });
                        _resetTimer();
                      },
                      correctPassword: 'admin', // Hardcoded admin lock for now
                    );"""

new_screensaver = """                    return ScreensaverScreen(
                      onUnlock: () {
                        setState(() {
                          _isScreensaverActive = false;
                        });
                        _resetTimer();
                      },
                      correctPassword: ref.watch(currentUserProvider)?.pinCode ?? '1234', 
                    );"""

if old_screensaver in content:
    content = content.replace(old_screensaver, new_screensaver)
    print("AppIdleWrapper patched.")
else:
    print("AppIdleWrapper patch failed.")

# Wait, `currentUserProvider` needs to be imported if it's not already.
import_auth = "import '../../application/auth/auth_service.dart';"
if import_auth not in content:
    content = "import '../../application/auth/auth_service.dart';\n" + content

with open('lib/src/presentation/widgets/app_idle_wrapper.dart', 'w') as f:
    f.write(content)
