import re

filepath = "lib/src/presentation/documents/documents_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

if "import '../widgets/print_dialog.dart';" not in content:
    content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../widgets/print_dialog.dart';")

# Replace invoice print call
# Currently it looks like:
# if (value == 'print') {
#   Navigator.push(context, MaterialPageRoute(
#     builder: (_) => PdfPreviewScreen(
#       title: '${invoice.documentType} #${invoice.invoiceNumber}',
#       buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(invoice.id, AppLocalizations.of(context)!),
#     ),
#   ));
# }

old_invoice_print = r"""                            if \(value == 'print'\) \{
                              Navigator\.push\(context, MaterialPageRoute\(
                                builder: \(\_\) => PdfPreviewScreen\(
                                  title: '\$\{invoice\.documentType\} #\$\{invoice\.invoiceNumber\}',
                                  buildPdf: \(\) => ref\.read\(pdfGeneratorProvider\)\.generateInvoicePdf\(invoice\.id, AppLocalizations\.of\(context\)!\),
                                \),
                              \)\);
                            \} else if"""

new_invoice_print = r"""                            if (value == 'print') {
                              final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                              if (options != null && context.mounted) {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => PdfPreviewScreen(
                                    title: '${invoice.documentType} #${invoice.invoiceNumber}',
                                    buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(invoice.id, options),
                                  ),
                                ));
                              }
                            } else if"""

content = re.sub(old_invoice_print, new_invoice_print, content, flags=re.MULTILINE)

# Now purchase print call
# if (value == 'print') {
#   Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Purchase ${purchase.purchaseNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generatePurchasePdf(purchase.id, AppLocalizations.of(context)!))));
# } else if

old_purchase_print = r"""                          if \(value == 'print'\) \{
                            Navigator\.push\(context, MaterialPageRoute\(builder: \(\_\) => PdfPreviewScreen\(title: "Purchase \$\{purchase\.purchaseNumber\}", buildPdf: \(\) => ref\.read\(pdfGeneratorProvider\)\.generatePurchasePdf\(purchase\.id, AppLocalizations\.of\(context\)!\)\)\)\);
                          \} else if"""

new_purchase_print = r"""                          if (value == 'print') {
                            final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                            if (options != null && context.mounted) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => PdfPreviewScreen(
                                  title: "Purchase ${purchase.purchaseNumber}",
                                  buildPdf: () => ref.read(pdfGeneratorProvider).generatePurchasePdf(purchase.id, options),
                                )
                              ));
                            }
                          } else if"""

content = re.sub(old_purchase_print, new_purchase_print, content, flags=re.MULTILINE)

# The analyze step also found issues at lines 117, 135, 179... wait, there are other screens/places?
# Ah, what if there are multiple occurrences because I didn't see them all?
# Let's replace any remaining `generateInvoicePdf(..., AppLocalizations.of(context)!)` dynamically if there are more.
import re
content = re.sub(
    r"generateInvoicePdf\((.*?), AppLocalizations\.of\(context\)!\)",
    r"generateInvoicePdf(\1, PrintOptions(layout: PrintLayout.a4, languageCode: Localizations.localeOf(context).languageCode))",
    content
)
content = re.sub(
    r"generatePurchasePdf\((.*?), AppLocalizations\.of\(context\)!\)",
    r"generatePurchasePdf(\1, PrintOptions(layout: PrintLayout.a4, languageCode: Localizations.localeOf(context).languageCode))",
    content
)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
