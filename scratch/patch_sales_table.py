import re

with open('lib/src/infrastructure/database/tables/sales.dart', 'r') as f:
    content = f.read()

content = content.replace("TextColumn get status => text()(); // 'UNPAID', 'PARTIAL', 'PAID'", 
"""TextColumn get status => text()(); // 'UNPAID', 'PARTIAL', 'PAID'
  TextColumn get paymentMethod => text().nullable()();""")

with open('lib/src/infrastructure/database/tables/sales.dart', 'w') as f:
    f.write(content)
print("Added paymentMethod to sales.dart")
