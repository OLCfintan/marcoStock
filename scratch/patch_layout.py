import re

with open('lib/src/presentation/layout/main_layout.dart', 'r') as f:
    content = f.read()

old_listtile = """        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,"""

new_listtile = """        child: ListTile(
          hoverColor: Color.lerp(Colors.purple, Colors.green, 0.5)!.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,"""

content = content.replace(old_listtile, new_listtile)

with open('lib/src/presentation/layout/main_layout.dart', 'w') as f:
    f.write(content)
print('Layout patched.')
