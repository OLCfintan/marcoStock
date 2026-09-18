import re

filepath = "lib/src/application/backup/backup_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace("import '../documents/print_options.dart';", "import '../../presentation/widgets/print_dialog.dart';")
content = content.replace("FilePicker.platform.getDirectoryPath", "FilePicker.getDirectoryPath")
content = content.replace("PrintOptions(showPrices: true)", "PrintOptions(layout: PrintLayout.a4, languageCode: 'fr')")
content = content.replace("prod.familyId", "prod.category")
content = content.replace("prod.buyingPrice", "prod.purchasePrice")

with open(filepath, 'w') as f:
    f.write(content)
print("done")
