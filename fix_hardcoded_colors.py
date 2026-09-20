import os
import re

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove hardcoded color: Colors.xxx.shadeYYY, from Card or Container
    content = re.sub(r'color:\s*Colors\.(teal|blue|grey)\.shade\d+,?', '', content)
    
    # Also fix some other specific things in purchases_screen
    content = re.sub(r'color:\s*Colors\.white,', '', content) # usually inside decoration: BoxDecoration
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

for root, dirs, files in os.walk('lib/src/presentation'):
    for name in files:
        if name.endswith('.dart'):
            fix_file(os.path.join(root, name))

