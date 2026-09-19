import os

target_import = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';"
new_import = "import 'package:marko_group/src/localization/arb/app_localizations.dart';"

count = 0
for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
            
            if target_import in content:
                content = content.replace(target_import, new_import)
                with open(filepath, 'w') as f:
                    f.write(content)
                count += 1

print(f"Updated {count} files.")
