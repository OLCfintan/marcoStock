import re

filepath = "lib/src/application/documents/pdf_generator.dart"
with open(filepath, 'r') as f:
    content = f.read()

# 1. Add import for flutter/services.dart if not present
if "import 'package:flutter/services.dart';" not in content:
    content = "import 'package:flutter/services.dart';\n" + content

# 2. Modify _addPages to accept bgImage
old_add_pages = r"""  void _addPages\(pw.Document doc, PrintOptions options, pw.TextDirection textDir, List<pw.Widget> Function\(\) buildContent\) \{
    if \(options.layout == PrintLayout.a4_2up\) \{
      doc.addPage\(
        pw.Page\(
          pageFormat: PdfPageFormat.a4.landscape,
          textDirection: textDir,
          margin: const pw.EdgeInsets.all\(24\),
          build: \(context\) \{
            return pw.Row\(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: \[
                pw.Expanded\(child: pw.Column\(children: buildContent\(\)\)\),
                pw.SizedBox\(width: 48\),
                pw.Expanded\(child: pw.Column\(children: buildContent\(\)\)\),
              \],
            \);
          \},
        \),
      \);
    \} else \{
      doc.addPage\(
        pw.MultiPage\(
          pageFormat: options.layout == PrintLayout.a5 \? PdfPageFormat.a5 : PdfPageFormat.a4,
          textDirection: textDir,
          margin: const pw.EdgeInsets.all\(32\),
          build: \(context\) => buildContent\(\),
        \),
      \);
    \}
  \}"""

new_add_pages = r"""  void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, List<pw.Widget> Function() buildContent) {
    pw.Widget? backgroundBuilder(pw.Context context) {
      if (bgImage == null) return null;
      return pw.FullPage(
        ignoreMargins: true,
        child: pw.Center(
          child: pw.Opacity(
            opacity: 0.15,
            child: pw.Image(bgImage, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    if (options.layout == PrintLayout.a4_2up) {
      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4.landscape,
            textDirection: textDir,
            margin: const pw.EdgeInsets.all(24),
            buildBackground: backgroundBuilder,
          ),
          build: (context) {
            return pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: pw.Column(children: buildContent())),
                pw.SizedBox(width: 48),
                pw.Expanded(child: pw.Column(children: buildContent())),
              ],
            );
          },
        ),
      );
    } else {
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: options.layout == PrintLayout.a5 ? PdfPageFormat.a5 : PdfPageFormat.a4,
            textDirection: textDir,
            margin: const pw.EdgeInsets.all(32),
            buildBackground: backgroundBuilder,
          ),
          build: (context) => buildContent(),
        ),
      );
    }
  }"""

content = re.sub(old_add_pages, new_add_pages, content)

# 3. Modify generateInvoicePdf to load the pdf_logo.jpeg and pass it to _addPages
old_generate_invoice = r"""    final textDir = l10n.localeName.startsWith\('ar'\) \? pw.TextDirection.rtl : pw.TextDirection.ltr;

    _addPages\(doc, options, textDir, \(\) => \["""

new_generate_invoice = r"""    final textDir = l10n.localeName.startsWith('ar') ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    pw.ImageProvider? watermarkBg;
    try {
      final ByteData data = await rootBundle.load('assets/images/pdf_logo.jpeg');
      final Uint8List watermarkBytes = data.buffer.asUint8List();
      watermarkBg = pw.MemoryImage(watermarkBytes);
    } catch (e) {
      print('Could not load watermark: $e');
    }

    _addPages(doc, options, textDir, watermarkBg, () => ["""

content = re.sub(old_generate_invoice, new_generate_invoice, content)

# 4. Modify generatePurchasePdf the same way
old_generate_purchase = r"""    final textDir = l10n.localeName.startsWith\('ar'\) \? pw.TextDirection.rtl : pw.TextDirection.ltr;

    _addPages\(doc, options, textDir, \(\) => \["""

new_generate_purchase = r"""    final textDir = l10n.localeName.startsWith('ar') ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    pw.ImageProvider? watermarkBg;
    try {
      final ByteData data = await rootBundle.load('assets/images/pdf_logo.jpeg');
      final Uint8List watermarkBytes = data.buffer.asUint8List();
      watermarkBg = pw.MemoryImage(watermarkBytes);
    } catch (e) {
      print('Could not load watermark: $e');
    }

    _addPages(doc, options, textDir, watermarkBg, () => ["""

content = re.sub(old_generate_purchase, new_generate_purchase, content)


with open(filepath, 'w') as f:
    f.write(content)
print("Updated pdf_generator.dart with watermark")
