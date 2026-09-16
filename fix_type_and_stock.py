import re

filepath = "lib/src/application/sales/sales_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Fix the client type check
content = content.replace("(client?.type == 'MAGAZIN' || client?.id == 'MAGAZIN_01')", "(client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01')")
content = content.replace("(client.type == 'MAGAZIN' || client.id == 'MAGAZIN_01')", "(client.type == 'MAGAZIN' || client.type == 'SPECIAL' || client.id == 'MAGAZIN_01')")
content = content.replace("(client?.type != 'MAGAZIN' && client?.id != 'MAGAZIN_01')", "(client?.type != 'MAGAZIN' && client?.type != 'SPECIAL' && client?.id != 'MAGAZIN_01')")

# Add the stock check logic in _deductStock
old_deduct = r"""    final currentQty = balance\?\.quantity \?\? Decimal.zero;
    
    // Mathematically preserve exact balances even if they go negative
    final newQty = currentQty - actualQuantityToDeduct;"""

new_deduct = r"""    final currentQty = balance?.quantity ?? Decimal.zero;
    
    // Prevent selling stock we don't have mathematically
    if (currentQty < actualQuantityToDeduct) {
        throw Exception('Insufficient stock. Available: ${currentQty.toStringAsFixed(2)}, Requested: ${actualQuantityToDeduct.toStringAsFixed(2)}');
    }
    
    // Mathematically preserve exact balances
    final newQty = currentQty - actualQuantityToDeduct;"""

content = re.sub(old_deduct, new_deduct, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated sales_service.dart")
