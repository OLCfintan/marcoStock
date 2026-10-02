import re

with open('lib/src/presentation/widgets/logo_loader.dart', 'r') as f:
    content = f.read()

# Remove the invalid import
content = content.replace("import 'dart:math' as math;", "")

# Add import at the top
if "import 'dart:math' as math;" not in content:
    content = "import 'dart:math' as math;\n" + content

with open('lib/src/presentation/widgets/logo_loader.dart', 'w') as f:
    f.write(content)
print("LogoLoader syntax fixed.")
