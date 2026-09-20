import re

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()

# Fix groupsSpace
content = content.replace("groupsSpace: 0,", "groupsSpace: 32,")
# Change alignment to spaceAround so the bars spread out
content = content.replace("alignment: BarChartAlignment.center,", "alignment: BarChartAlignment.spaceAround,")

# Fix width
old_width = "width: sales.isEmpty ? 32 : ((constraints.maxWidth - 60) / sales.length),"
new_width = "width: 32,"
content = content.replace(old_width, new_width)

# Fix border radius (make it slightly rounded at the top)
content = content.replace("borderRadius: BorderRadius.zero,", "borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),")

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)
