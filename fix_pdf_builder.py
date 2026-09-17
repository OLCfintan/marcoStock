import re

filepath = "lib/src/application/documents/pdf_generator.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_builder = r"""    pw.Widget\? backgroundBuilder\(pw.Context context\) \{
      if \(bgImage == null\) return null;"""

new_builder = r"""    pw.Widget backgroundBuilder(pw.Context context) {
      if (bgImage == null) return pw.Container();"""

content = re.sub(old_builder, new_builder, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated pdf builder return type")
