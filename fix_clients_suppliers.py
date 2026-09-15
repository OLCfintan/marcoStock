with open("lib/src/presentation/clients/clients_screen.dart", "r") as f:
    lines = f.readlines()
# keep up to line 147, and the last line '}\n'
with open("lib/src/presentation/clients/clients_screen.dart", "w") as f:
    f.writelines(lines[:147])
    f.write("}\n")

with open("lib/src/presentation/suppliers/suppliers_screen.dart", "r") as f:
    lines = f.readlines()
with open("lib/src/presentation/suppliers/suppliers_screen.dart", "w") as f:
    f.writelines(lines[:147])
    f.write("}\n")
