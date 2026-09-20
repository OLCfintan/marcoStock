import os
import re

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    # Look for Text('... | Status: ${invoice.status}') and similar
    if 'Status:' in content or 'status:' in content:
        # Actually it's easier to manually regex this
        pass
