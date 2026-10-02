import re

with open('lib/main.dart', 'r') as f:
    content = f.read()

import_stmt = "import 'src/presentation/widgets/magnifier_wrapper.dart';"
new_import = "import 'src/presentation/widgets/magnifier_wrapper.dart';\nimport 'src/presentation/widgets/app_idle_wrapper.dart';"
content = content.replace(import_stmt, new_import)

old_router = "      builder: (context, child) => MagnifierWrapper(child: child!),"
new_router = "      builder: (context, child) => AppIdleWrapper(child: MagnifierWrapper(child: child!)),"
content = content.replace(old_router, new_router)

with open('lib/main.dart', 'w') as f:
    f.write(content)
print('main.dart patched.')
