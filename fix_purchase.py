import re

with open('lib/src/application/purchases/purchase_service.dart', 'r') as f:
    content = f.read()

# Make sure we import the helper
if 'stock_helpers.dart' not in content:
    content = content.replace("import '../../infrastructure/repositories/product_repository.dart';", "import '../../infrastructure/repositories/product_repository.dart';\nimport '../stock/stock_helpers.dart';")

def replace_stock_logic(text):
    # Find the base product retrieval logic in deletePurchase and restorePurchase
    pattern1 = re.compile(r'final baseProducts = await \(_db\.select\(_db\.products\)\.\.where\(\(t\) => t\.name\.equals\(product\.name\) & t\.packagingType\.equals\(\'Unit\'\)\)\)\.get\(\);\s*final baseProduct = baseProducts\.isNotEmpty \? baseProducts\.first : product;')
    text = pattern1.sub('final baseProduct = await getDeterministicBaseProduct(_db, product);', text)
    
    # Find the logic in _addStock
    pattern2 = re.compile(r'final familyProducts = await \(_db\.select\(_db\.products\)\.\.where\(\(t\) => t\.name\.equals\(product\.name\)\)\)\.get\(\);\s*final baseProduct = familyProducts\.firstWhere\(\s*\(p\) => p\.unitSize == Decimal\.one,\s*orElse: \(\) => familyProducts\.firstWhere\(\s*\(p\) => p\.packagingType == \'Unit\' \|\| p\.packagingType == null \|\| p\.packagingType == \'\',\s*orElse: \(\) => product,\s*\),\s*\);')
    text = pattern2.sub('final baseProduct = await getDeterministicBaseProduct(_db, product);', text)
    return text

content = replace_stock_logic(content)

with open('lib/src/application/purchases/purchase_service.dart', 'w') as f:
    f.write(content)

