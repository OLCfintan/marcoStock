import re

with open('lib/src/application/sales/sales_service.dart', 'r') as f:
    content = f.read()

if 'stock_helpers.dart' not in content:
    content = content.replace("import '../../infrastructure/repositories/stock_repository.dart';", "import '../../infrastructure/repositories/stock_repository.dart';\nimport '../stock/stock_helpers.dart';")

def replace_stock_logic(text):
    # _deductStock pattern
    pattern_deduct = re.compile(r'String targetProductId = product\.id;\s*Decimal actualQuantityToDeduct = quantity;\s*// Always convert to the Root Base Product mathematically to maintain global consistency\s*if \(product\.unitSize != Decimal\.one\) \{\s*final familyProducts = await \(_db\.select\(_db\.products\)\.\.where\(\(t\) => t\.name\.equals\(product\.name\)\)\)\.get\(\);\s*final baseProduct = familyProducts\.firstWhere\(\s*\(p\) => p\.unitSize == Decimal\.one,\s*orElse: \(\) => familyProducts\.firstWhere\(\s*\(p\) => p\.packagingType == \'Unit\' \|\| p\.packagingType == null \|\| p\.packagingType == \'\',\s*orElse: \(\) => product,\s*\),\s*\);\s*targetProductId = baseProduct\.id;\s*actualQuantityToDeduct = quantity \* product\.unitSize;\s*\}')
    
    replace_deduct = """final baseProduct = await getDeterministicBaseProduct(_db, product);
    String targetProductId = baseProduct.id;
    Decimal actualQuantityToDeduct = quantity * product.unitSize;"""
    
    text = pattern_deduct.sub(replace_deduct, text)
    
    # _restoreStock pattern
    pattern_restore = re.compile(r'String targetProductId = product\.id;\s*Decimal actualQtyToAdd = quantity;\s*if \(product\.unitSize != Decimal\.one\) \{\s*final familyProducts = await \(_db\.select\(_db\.products\)\.\.where\(\(t\) => t\.name\.equals\(product\.name\)\)\)\.get\(\);\s*final baseProduct = familyProducts\.firstWhere\(\s*\(p\) => p\.unitSize == Decimal\.one,\s*orElse: \(\) => familyProducts\.firstWhere\(\s*\(p\) => p\.packagingType == \'Unit\' \|\| p\.packagingType == null \|\| p\.packagingType == \'\',\s*orElse: \(\) => product,\s*\),\s*\);\s*targetProductId = baseProduct\.id;\s*actualQtyToAdd = quantity \* product\.unitSize;\s*\}')
    
    replace_restore = """final baseProduct = await getDeterministicBaseProduct(_db, product);
    String targetProductId = baseProduct.id;
    Decimal actualQtyToAdd = quantity * product.unitSize;"""
    
    text = pattern_restore.sub(replace_restore, text)
    
    return text

content = replace_stock_logic(content)

with open('lib/src/application/sales/sales_service.dart', 'w') as f:
    f.write(content)

