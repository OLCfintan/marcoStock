import re

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()

old_name = """final clientName = normalClients.firstWhere((c) => c.id == inv.clientId).name;"""
new_name = """final clientName = inv.clientId == null ? 'Walk-In Client' : normalClients.firstWhere((c) => c.id == inv.clientId, orElse: () => normalClients.first).name;"""

content = content.replace(old_name, new_name)

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)

