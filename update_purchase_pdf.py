import re

filepath = "lib/src/application/documents/pdf_generator.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_add = r"""    doc\.addPage\(
      pw\.MultiPage\(
        pageFormat: PdfPageFormat\.a4,
        textDirection: textDir,
        margin: const pw\.EdgeInsets\.all\(32\),
        build: \(pw\.Context context\) \{
          return \[
            pw\.Row\(
              mainAxisAlignment: pw\.MainAxisAlignment\.spaceBetween,
              children: \["""

new_add = r"""    _addPages(doc, options, textDir, () => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: ["""

content = re.sub(old_add, new_add, content, flags=re.MULTILINE)

old_end = r"""              \),
            \),
          \];
        \},
      \),
    \);

    return doc\.save\(\);"""

new_end = r"""              ),
            ),
    ]);

    return doc.save();"""

content = re.sub(old_end, new_end, content, flags=re.MULTILINE)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
