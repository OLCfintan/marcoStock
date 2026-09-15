import re

filepath = "lib/src/application/documents/pdf_generator.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Add import for PrintOptions
if "import '../../presentation/widgets/print_dialog.dart';" not in content:
    content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../../presentation/widgets/print_dialog.dart';")

# Add the _addPages helper to PdfGeneratorService class
helper_code = """  void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, List<pw.Widget> Function() buildContent) {
    if (options.layout == PrintLayout.a4_2up) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          textDirection: textDir,
          margin: const pw.EdgeInsets.all(24),
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
          pageFormat: options.layout == PrintLayout.a5 ? PdfPageFormat.a5 : PdfPageFormat.a4,
          textDirection: textDir,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => buildContent(),
        ),
      );
    }
  }

"""

if "void _addPages(" not in content:
    # insert it right after the constructor
    content = content.replace("PdfGeneratorService(this._db, this._settings);", "PdfGeneratorService(this._db, this._settings);\n\n" + helper_code)

# 1. Update generateInvoicePdf signature and locale loading
old_invoice_sig = r"Future<Uint8List> generateInvoicePdf\(String invoiceId, AppLocalizations l10n\) async \{"
new_invoice_sig = r"""Future<Uint8List> generateInvoicePdf(String invoiceId, PrintOptions options) async {
    final l10n = await AppLocalizations.delegate.load(Locale(options.languageCode));"""
content = re.sub(old_invoice_sig, new_invoice_sig, content)

# 2. Update doc.addPage for generateInvoicePdf
old_invoice_add = r"""    doc\.addPage\(
      pw\.MultiPage\(
        pageFormat: PdfPageFormat\.a4,
        textDirection: textDir,
        margin: const pw\.EdgeInsets\.all\(32\),
        build: \(pw\.Context context\) \{
          return \[
            _buildHeader\(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, logoImage, l10n\),
            pw\.SizedBox\(height: 32\),
            _buildInvoiceTable\(lines, productMap, l10n\),
            pw\.SizedBox\(height: 16\),
            _buildTotals\(invoice, l10n\),
            pw\.Spacer\(\),
            pw\.Divider\(\),
            pw\.Container\(
              alignment: pw\.Alignment\.center,
              child: pw\.Text\(l10n\.pdfThankYou, style: const pw\.TextStyle\(color: PdfColors\.grey\)\),
            \),
          \];
        \},
      \),
    \);"""
new_invoice_add = r"""    _addPages(doc, options, textDir, () => [
      _buildHeader(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, logoImage, l10n),
      pw.SizedBox(height: 32),
      _buildInvoiceTable(lines, productMap, l10n),
      pw.SizedBox(height: 16),
      _buildTotals(invoice, l10n),
      pw.Spacer(),
      pw.Divider(),
      pw.Container(
        alignment: pw.Alignment.center,
        child: pw.Text(l10n.pdfThankYou, style: const pw.TextStyle(color: PdfColors.grey)),
      ),
    ]);"""
content = re.sub(old_invoice_add, new_invoice_add, content, flags=re.MULTILINE | re.DOTALL)

# 3. Update generatePurchasePdf signature and locale loading
old_purchase_sig = r"Future<Uint8List> generatePurchasePdf\(String purchaseId, AppLocalizations l10n\) async \{"
new_purchase_sig = r"""Future<Uint8List> generatePurchasePdf(String purchaseId, PrintOptions options) async {
    final l10n = await AppLocalizations.delegate.load(Locale(options.languageCode));"""
content = re.sub(old_purchase_sig, new_purchase_sig, content)

# 4. Update doc.addPage for generatePurchasePdf
# Since it's huge, I'll just find the start and end of it.
import sys
# It's better to just manually rewrite it using substring.
start_str = "doc.addPage("
end_str = "    return doc.save();"

with open(filepath, 'w') as f:
    f.write(content)

