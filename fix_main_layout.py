with open("lib/src/presentation/layout/main_layout.dart", "r") as f:
    content = f.read()

if "shortcuts_provider.dart" not in content:
    content = content.replace("import '../../application/auth/auth_service.dart';", "import '../../application/auth/auth_service.dart';\nimport '../../application/system/shortcuts_provider.dart';\nimport 'package:flutter/services.dart';")

old_return = "    return LayoutBuilder("
new_return = """    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          ref.read(newSaleCartTriggerProvider.notifier).state++;
          context.go('/sales');
        },
      },
      child: Focus(
        autofocus: true,
        canRequestFocus: false,
        onFocusChange: (f) {},
        descendantsAreFocusable: true,
        child: LayoutBuilder("""

content = content.replace(old_return, new_return)

old_end = """        }
      },
    );
  }

  Widget _buildNavItem"""

new_end = """        }
      },
    ),
    ),
    );
  }

  Widget _buildNavItem"""

content = content.replace(old_end, new_end)

with open("lib/src/presentation/layout/main_layout.dart", "w") as f:
    f.write(content)
print("Done")
