import re

filepath = "lib/src/infrastructure/repositories/stock_repository.dart"
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace("if (balance.quantity <= Decimal.zero) continue;", "// if (balance.quantity <= Decimal.zero) continue; // Allow viewing zero and negative stocks for auditing")

with open(filepath, 'w') as f:
    f.write(content)
print("Updated stock_repository.dart")
