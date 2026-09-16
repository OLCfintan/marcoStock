import re

filepath = "lib/src/application/sales/sales_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Replace all occurrences of client?.type == 'SPECIAL' with (client?.type == 'MAGAZIN' || client?.id == 'MAGAZIN_01')
content = content.replace("client?.type == 'SPECIAL'", "(client?.type == 'MAGAZIN' || client?.id == 'MAGAZIN_01')")
content = content.replace("client.type == 'SPECIAL'", "(client.type == 'MAGAZIN' || client.id == 'MAGAZIN_01')")
content = content.replace("client?.type != 'SPECIAL'", "(client?.type != 'MAGAZIN' && client?.id != 'MAGAZIN_01')")

with open(filepath, 'w') as f:
    f.write(content)
print("Updated sales_service.dart")
