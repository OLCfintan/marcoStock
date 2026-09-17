import re

filepath = "lib/src/application/documents/pdf_generator.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_try_load = r"""    pw.ImageProvider\? watermarkBg;
    try \{
      final ByteData data = await rootBundle.load\('assets/images/pdf_logo.jpeg'\);
      final Uint8List watermarkBytes = data.buffer.asUint8List\(\);
      watermarkBg = pw.MemoryImage\(watermarkBytes\);
    \} catch \(e\) \{
      print\('Could not load watermark: \$e'\);
    \}"""

new_try_load = r"""    pw.ImageProvider? watermarkBg;
    try {
      final file = File('assets/images/pdf_logo.jpeg');
      if (file.existsSync()) {
        watermarkBg = pw.MemoryImage(file.readAsBytesSync());
      } else {
        final ByteData data = await rootBundle.load('assets/images/pdf_logo.jpeg');
        watermarkBg = pw.MemoryImage(data.buffer.asUint8List());
      }
    } catch (e) {
      print('Could not load watermark: $e');
    }"""

content = re.sub(old_try_load, new_try_load, content)

old_opacity = r"opacity: 0.15,"
new_opacity = r"opacity: 0.35,"

content = re.sub(old_opacity, new_opacity, content)

# Change FullPage to Watermark to ensure it is centered perfectly and drawn correctly
old_builder = r"""    pw.Widget backgroundBuilder\(pw.Context context\) \{
      if \(bgImage == null\) return pw.Container\(\);
      return pw.FullPage\(
        ignoreMargins: true,
        child: pw.Center\(
          child: pw.Opacity\(
            opacity: 0.35,
            child: pw.Image\(bgImage, fit: pw.BoxFit.contain\),
          \),
        \),
      \);
    \}"""

new_builder = r"""    pw.Widget backgroundBuilder(pw.Context context) {
      if (bgImage == null) return pw.Container();
      return pw.Watermark(
        child: pw.Opacity(
          opacity: 0.25,
          child: pw.Image(bgImage, fit: pw.BoxFit.contain),
        ),
      );
    }"""

content = re.sub(old_builder, new_builder, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated pdf load logic")
