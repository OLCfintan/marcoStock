import re

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()

old_bar_rod = """                          color: Colors.blueAccent,
                          width: sales.isEmpty ? 32 : (constraints.maxWidth / sales.length),
                          borderRadius: BorderRadius.zero,"""

new_bar_rod = """                          color: Colors.blueAccent,
                          width: sales.isEmpty ? 32 : (constraints.maxWidth / sales.length),
                          borderRadius: BorderRadius.zero,
                          borderSide: const BorderSide(color: Colors.white, width: 1),"""

content = content.replace(old_bar_rod, new_bar_rod)

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)
