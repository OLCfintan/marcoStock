import re

with open('lib/src/application/dashboard/dashboard_providers.dart', 'r') as f:
    content = f.read()

old_query = """t.clientId.isIn(normalIds)"""
new_query = """(t.clientId.isIn(normalIds) | t.clientId.isNull())"""

content = content.replace(old_query, new_query)

with open('lib/src/application/dashboard/dashboard_providers.dart', 'w') as f:
    f.write(content)

