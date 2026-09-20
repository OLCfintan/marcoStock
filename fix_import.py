import re

with open('lib/src/application/dashboard/dashboard_providers.dart', 'r') as f:
    content = f.read()

# Remove the incorrectly placed import
content = content.replace("import 'dart:collection';\n\nfinal salesChartDataProvider", "final salesChartDataProvider")

# Add it to the top if not present
if "import 'dart:collection';" not in content:
    content = "import 'dart:collection';\n" + content

with open('lib/src/application/dashboard/dashboard_providers.dart', 'w') as f:
    f.write(content)
