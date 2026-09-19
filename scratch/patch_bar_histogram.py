import re

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()

old_chart_data = """                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,"""

new_chart_data = """                BarChartData(
                  alignment: BarChartAlignment.center,
                  groupsSpace: 0,
                  maxY: maxY,"""

content = content.replace(old_chart_data, new_chart_data)


old_bar_width = """                          width: sales.isEmpty ? 32 : (constraints.maxWidth / sales.length).clamp(10.0, 100.0) * 0.9,"""

new_bar_width = """                          width: sales.isEmpty ? 32 : (constraints.maxWidth / sales.length),"""

content = content.replace(old_bar_width, new_bar_width)

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)

