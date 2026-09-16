import re

filepath = "lib/src/application/stock/stock_helpers.dart"
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace("return convertedMagnitude.toDecimal(scaleOnInfinitePrecision: 6);", "return convertedMagnitude;")

with open(filepath, 'w') as f:
    f.write(content)
print("Fixed syntax error")
