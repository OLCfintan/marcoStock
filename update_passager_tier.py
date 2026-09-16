import re

filepath = "lib/src/infrastructure/database/app_database.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Replace 'Tier 1' with 'Tier 3' for WALKIN_CLIENT_01
# We can search for WALKIN_CLIENT_01 block and replace Tier 1 with Tier 3
block_pattern = r"(id:\s*'WALKIN_CLIENT_01'[\s\S]*?)tier:\s*const\s+Value\('Tier 1'\)"
content = re.sub(block_pattern, r"\1tier: const Value('Tier 3')", content)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
