import re

with open('lib/main.dart', 'r') as f:
    content = f.read()

# Add import
import_stmt = "import 'src/application/settings/settings_service.dart';"
new_import = "import 'src/application/settings/settings_service.dart';\nimport 'src/presentation/widgets/magnifier_wrapper.dart';"
content = content.replace(import_stmt, new_import)

# Add builder
old_router = "    return MaterialApp.router("
new_router = """    return MaterialApp.router(
      builder: (context, child) => MagnifierWrapper(child: child!),"""
content = content.replace(old_router, new_router)

with open('lib/main.dart', 'w') as f:
    f.write(content)
print('main.dart patched.')
