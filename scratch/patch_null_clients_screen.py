import re

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()

old_query = """t.clientId.isIn(normalIds)"""
new_query = """(t.clientId.isIn(normalIds) | t.clientId.isNull())"""

content = content.replace(old_query, new_query)

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)

