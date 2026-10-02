import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  // 1. Remove Thank You
  content = content.replaceAll(
    "pw.SizedBox(height: 30),\n      pw.Divider(),\n      pw.Container(\n        alignment: pw.Alignment.center,\n        child: _bidiText(l10n.pdfThankYou, style: const pw.TextStyle(color: PdfColors.grey)),\n      ),\n",
    ""
  );

  // 2. Set pageColor: PdfColors.white
  content = content.replaceAll(
    "margin: const pw.EdgeInsets.all(24),",
    "margin: const pw.EdgeInsets.all(24),\n            pageColor: PdfColors.white,"
  );
  content = content.replaceAll(
    "margin: const pw.EdgeInsets.all(32),",
    "margin: const pw.EdgeInsets.all(32),\n            pageColor: PdfColors.white,"
  );

  // 3. Make watermarkBg the default logoImage
  content = content.replaceAll(
    "_buildHeader(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, companyIce, companyRc, companyRib, companyEmail, logoImage, l10n)",
    "_buildHeader(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, companyIce, companyRc, companyRib, companyEmail, logoImage ?? watermarkBg, l10n)"
  );
  
  // Apply logoImage ?? watermarkBg for generatePurchasePdf as well (Wait, they said "all the invoice documents", I'll just change the variable logoImage to include fallback)
  content = content.replaceAll(
    "final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;",
    "pw.ImageProvider? logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;"
  );

  file.writeAsStringSync(content);
}
