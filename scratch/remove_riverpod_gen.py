import re

with open('pubspec.yaml', 'r') as f:
    content = f.read()

content = re.sub(r'\s*riverpod_annotation:.*', '', content)
content = re.sub(r'\s*riverpod_generator:.*', '', content)

with open('pubspec.yaml', 'w') as f:
    f.write(content)

