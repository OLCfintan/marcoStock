import re

filepath = "lib/src/application/sales/sales_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_logic = r"""    // Clamp to zero: stock may have been manually deleted, transferred, or consumed
    final actualDeduction = currentQty < actualQuantityToDeduct \? currentQty : actualQuantityToDeduct;
    final newQty = currentQty - actualDeduction;"""

new_logic = r"""    // Mathematically preserve exact balances even if they go negative
    final newQty = currentQty - actualQuantityToDeduct;"""

content = re.sub(old_logic, new_logic, content)
with open(filepath, 'w') as f:
    f.write(content)
print("Removed clamp from sales_service.dart")
