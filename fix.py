with open("lib/src/presentation/sales/pos_screen.dart", "r") as f:
    lines = f.readlines()

for i in range(len(lines)-1, -1, -1):
    if "return Row(" in lines[i]:
        # we found the Row at the end of the builder
        pass
    if "    );\n" == lines[i] and "  }\n" == lines[i+1] and "}\n" == lines[i+2]:
        lines[i] = "      ),\n    ),\n    );\n"
        break

with open("lib/src/presentation/sales/pos_screen.dart", "w") as f:
    f.writelines(lines)
