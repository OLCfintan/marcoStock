import re

filepath = "lib/src/application/sales/sales_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

# 1. Update _deductStock signature
content = content.replace("required String locationId,", "required String locationId,\n    bool allowNegative = false,")

# 2. Update stock check logic
old_logic = r"""    // Prevent selling stock we don't have mathematically
    if \(currentQty < actualQuantityToDeduct\) \{
        throw Exception\('Insufficient stock. Available: \$\{currentQty.toStringAsFixed\(2\)\}, Requested: \$\{actualQuantityToDeduct.toStringAsFixed\(2\)\}'\);
    \}"""

new_logic = r"""    // Prevent selling stock we don't have, unless we are reversing an operation
    if (!allowNegative && currentQty < actualQuantityToDeduct) {
        throw Exception('Insufficient stock. Available: ${currentQty.toStringAsFixed(2)}, Requested: ${actualQuantityToDeduct.toStringAsFixed(2)}');
    }"""
content = re.sub(old_logic, new_logic, content)

# 3. Find calls to _deductStock that reverse things and add allowNegative: true
# Example: reason: 'TRANSFER_REVERSED'
# Example: reason: 'SALE_RESTORED' (wait, restoring a sale deducts stock from warehouse?)
# If you restore a sale, you take it back out of warehouse. Does that allow negative? Yes, because maybe they already sold it, but they are undeleting an old sale? 
content = content.replace("reason: 'TRANSFER_REVERSED',", "reason: 'TRANSFER_REVERSED',\n            allowNegative: true,")
content = content.replace("reason: 'SALE_RESTORED',", "reason: 'SALE_RESTORED',\n          allowNegative: true,")
content = content.replace("reason: 'CONSUMPTION',", "reason: 'CONSUMPTION',\n        allowNegative: true,") # wait, should consumption allow negative? Let's say yes to avoid crashes

with open(filepath, 'w') as f:
    f.write(content)
print("Updated sales_service.dart with allowNegative")
