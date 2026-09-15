import re

with open('lib/src/application/stock/stock_transfer_service.dart', 'r') as f:
    content = f.read()

if 'stock_helpers.dart' not in content:
    content = content.replace("import '../../infrastructure/database/app_database.dart';", "import '../../infrastructure/database/app_database.dart';\nimport 'stock_helpers.dart';")

def replace_stock_logic(text):
    pattern = re.compile(r'String targetProductId = product\.id;\s*final unitSize = product\.unitSize;\s*if \(product\.unitSize != Decimal\.one\) \{\s*final familyProducts = await \(_db\.select\(_db\.products\)\.\.where\(\(t\) => t\.name\.equals\(product\.name\)\)\)\.get\(\);\s*// Prefer the exact product mathematically defined as the base \(unitSize == 1\)\s*final baseProduct = familyProducts\.firstWhere\(\s*\(p\) => p\.unitSize == Decimal\.one,\s*orElse: \(\) => familyProducts\.firstWhere\(\s*\(p\) => p\.packagingType == \'Unit\' \|\| p\.packagingType == null \|\| p\.packagingType == \'\',\s*orElse: \(\) => product,\s*\),\s*\);\s*targetProductId = baseProduct\.id;\s*\}')
    
    replace_text = """final baseProduct = await getDeterministicBaseProduct(_db, product);
      String targetProductId = baseProduct.id;
      final unitSize = product.unitSize;"""
    
    return pattern.sub(replace_text, text)

content = replace_stock_logic(content)

with open('lib/src/application/stock/stock_transfer_service.dart', 'w') as f:
    f.write(content)

