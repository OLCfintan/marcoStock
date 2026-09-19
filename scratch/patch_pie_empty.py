import re

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()

old_code = """                data: (data) {
                  if (data.isEmpty) return const Center(child: Text('No stock data'));
                  final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.amber, Colors.cyan];"""

new_code = """                data: (data) {
                  final validData = data.where((d) => d.value > 0).toList();
                  if (validData.isEmpty) return const Center(child: Text('No stock data', style: TextStyle(color: Colors.black)));
                  final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.amber, Colors.cyan];"""

content = content.replace(old_code, new_code)

old_pie = """sections: data.where((d) => d.value > 0).toList().asMap().entries.map((e) {"""
new_pie = """sections: validData.asMap().entries.map((e) {"""
content = content.replace(old_pie, new_pie)

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)
