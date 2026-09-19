import re

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()

old_code = """                  final validData = data.where((d) => d.value > 0).toList();
                  if (validData.isEmpty) return const Center(child: Text('No stock data', style: TextStyle(color: Colors.black)));"""

new_code = """                  final validData = data.where((d) => d.value > 0).toList();
                  validData.sort((a, b) => b.value.compareTo(a.value));
                  if (validData.isEmpty) return const Center(child: Text('No stock data', style: TextStyle(color: Colors.black)));"""

content = content.replace(old_code, new_code)
with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)

