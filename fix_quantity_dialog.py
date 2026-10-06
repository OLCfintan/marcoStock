with open("lib/src/presentation/widgets/quantity_selector_dialog.dart", "r") as f:
    lines = f.readlines()

new_lines = []
skip = False
for line in lines:
    if "content: Focus(" in line:
        skip = True
        new_lines.append("      content: Column(\n")
        continue
    if skip and "        child: Column(" in line:
        skip = False
        continue
    if skip:
        continue
    
    # Also remove the two closing brackets for the Focus widget.
    # They should be at the end before `actions:`
    if line.strip() == ")," and new_lines[-1].strip() == "]," and len(new_lines) > 5:
        # Wait, the structure is:
        # children: [ ... ]
        # ),
        # ),
        pass

    new_lines.append(line)

with open("lib/src/presentation/widgets/quantity_selector_dialog.dart", "w") as f:
    f.writelines(new_lines)
