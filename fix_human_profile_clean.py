import re

filepath = "lib/src/presentation/widgets/human_profile_dialog.dart"
with open(filepath, 'r') as f:
    content = f.read()

if "import 'print_dialog.dart';" not in content:
    content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'print_dialog.dart';")

# 1. Invoice onDoubleTap
old_invoice_onDoubleTap = r"""onDoubleTap: \(\) => Navigator\.push\(context, MaterialPageRoute\(builder: \(\_\) => PdfPreviewScreen\(title: "Invoice \$\{inv\.invoiceNumber\}", buildPdf: \(\) => ref\.read\(pdfGeneratorProvider\)\.generateInvoicePdf\(inv\.id, AppLocalizations\.of\(context\)!\)\)\)\),"""
new_invoice_onDoubleTap = r"""onDoubleTap: () async {
                  final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                  if (options != null && context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Invoice ${inv.invoiceNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(inv.id, options))));
                  }
                },"""
content = re.sub(old_invoice_onDoubleTap, new_invoice_onDoubleTap, content)

# 2. Invoice IconButton Print
old_invoice_icon = r"""IconButton\(icon: const Icon\(Icons\.print, color: Colors\.blueGrey, size: 20\), tooltip: 'Print Invoice', onPressed: \(\) => Navigator\.push\(context, MaterialPageRoute\(builder: \(\_\) => PdfPreviewScreen\(title: "Invoice \$\{inv\.invoiceNumber\}", buildPdf: \(\) => ref\.read\(pdfGeneratorProvider\)\.generateInvoicePdf\(inv\.id, AppLocalizations\.of\(context\)!\)\)\)\)\),"""
new_invoice_icon = r"""IconButton(icon: const Icon(Icons.print, color: Colors.blueGrey, size: 20), tooltip: 'Print Invoice', onPressed: () async {
                        final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                        if (options != null && context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Invoice ${inv.invoiceNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(inv.id, options))));
                        }
                      }),"""
content = re.sub(old_invoice_icon, new_invoice_icon, content)

# 3. Purchase onDoubleTap
old_purchase_onDoubleTap = r"""onDoubleTap: \(\) => Navigator\.push\(context, MaterialPageRoute\(builder: \(\_\) => PdfPreviewScreen\(title: "Purchase \$\{pur\.purchaseNumber\}", buildPdf: \(\) => ref\.read\(pdfGeneratorProvider\)\.generatePurchasePdf\(pur\.id, AppLocalizations\.of\(context\)!\)\)\)\),"""
new_purchase_onDoubleTap = r"""onDoubleTap: () async {
                  final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                  if (options != null && context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Purchase ${pur.purchaseNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generatePurchasePdf(pur.id, options))));
                  }
                },"""
content = re.sub(old_purchase_onDoubleTap, new_purchase_onDoubleTap, content)

# 4. Purchase IconButton Print
old_purchase_icon = r"""IconButton\(icon: const Icon\(Icons\.print, color: Colors\.blueGrey, size: 20\), tooltip: 'Print Purchase', onPressed: \(\) \{ Navigator\.push\(context, MaterialPageRoute\(builder: \(\_\) => PdfPreviewScreen\(title: "Purchase \$\{pur\.purchaseNumber\}", buildPdf: \(\) => ref\.read\(pdfGeneratorProvider\)\.generatePurchasePdf\(pur\.id, AppLocalizations\.of\(context\)!\)\)\)\); \}\),"""
new_purchase_icon = r"""IconButton(icon: const Icon(Icons.print, color: Colors.blueGrey, size: 20), tooltip: 'Print Purchase', onPressed: () async {
                        final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                        if (options != null && context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Purchase ${pur.purchaseNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generatePurchasePdf(pur.id, options))));
                        }
                      }),"""
content = re.sub(old_purchase_icon, new_purchase_icon, content)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
