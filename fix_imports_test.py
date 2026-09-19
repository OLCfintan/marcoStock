import os

target_import = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';"
new_import = "import 'package:marko_group/src/localization/arb/app_localizations.dart';"

filepath = 'test_l10n.dart'
if os.path.exists(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    if target_import in content:
        content = content.replace(target_import, new_import)
        with open(filepath, 'w') as f:
            f.write(content)
        print("Fixed test_l10n.dart")
