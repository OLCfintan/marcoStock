import re

filepath = "lib/src/presentation/widgets/human_profile_dialog.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Refactor Invoice trailing
old_inv_trailing = r"""                  trailing: Row\(
                    mainAxisSize: MainAxisSize.min,
                    children: \[
                      IconButton\(icon: const Icon\(Icons.print, color: Colors.blueGrey, size: 20\), tooltip: 'Print Invoice', onPressed: \(\) async \{
                        final options = await PrintDialog.show\(context, defaultLanguageCode: Localizations.localeOf\(context\).languageCode\);
                        if \(options != null && context.mounted\) \{
                          Navigator.push\(context, MaterialPageRoute\(builder: \(_\) => PdfPreviewScreen\(title: "Invoice \$\{inv.invoiceNumber\}", buildPdf: \(\) => ref.read\(pdfGeneratorProvider\).generateInvoicePdf\(inv.id, options\)\)\)\);
                        \}
                      \}\),
                      
                        IconButton\(icon: const Icon\(Icons.attach_money, color: Colors.green, size: 20\), tooltip: 'Record Payment', onPressed: \(\) \{
                          PaymentDialog.show\(context, entityId: inv.id, entityType: 'INVOICE', partnerId: widget.id, currentTotal: inv.total, currentlyPaid: inv.paidAmount\);
                        \}\),
                      IconButton\(icon: const Icon\(Icons.receipt_long, color: Colors.teal, size: 20\), tooltip: 'View Payments & Checks', onPressed: \(\) \{
                        ViewPaymentsDialog.show\(context, entityId: inv.id, entityType: 'INVOICE'\);
                      \}\),
                      if \(ref.watch\(currentUserProvider\)\?.role == 'ADMIN'\)
                         IconButton\(icon: const Icon\(Icons.delete, color: Colors.red, size: 20\), onPressed: \(\) async \{
                             final userId = ref.read\(currentUserProvider\)\?.id \?\? '';
                             await ref.read\(salesServiceProvider\).deleteInvoice\(inv.id, userId\);
                         \}\),
                    \]
                  \),"""

new_inv_trailing = r"""                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'print') {
                        final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                        if (options != null && context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Invoice ${inv.invoiceNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(inv.id, options))));
                        }
                      } else if (value == 'record_payment') {
                        PaymentDialog.show(context, entityId: inv.id, entityType: 'INVOICE', partnerId: widget.id, currentTotal: inv.total, currentlyPaid: inv.paidAmount);
                      } else if (value == 'view_payments') {
                        ViewPaymentsDialog.show(context, entityId: inv.id, entityType: 'INVOICE');
                      } else if (value == 'delete') {
                        final userId = ref.read(currentUserProvider)?.id ?? '';
                        await ref.read(salesServiceProvider).deleteInvoice(inv.id, userId);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'print', child: Text(AppLocalizations.of(context)?.printDocument ?? 'Print')),
                      PopupMenuItem(value: 'record_payment', child: Text(AppLocalizations.of(context)?.recordPayment ?? 'Record Payment')),
                      PopupMenuItem(value: 'view_payments', child: Text(AppLocalizations.of(context)?.viewPaymentsChecks ?? 'View Payments')),
                      if (ref.watch(currentUserProvider)?.role == 'ADMIN')
                        PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)?.deleteStr ?? 'Delete', style: const TextStyle(color: Colors.red))),
                    ],
                  ),"""

content = re.sub(old_inv_trailing, new_inv_trailing, content)

# Refactor Purchase trailing
old_pur_trailing = r"""                  trailing: Row\(
                    mainAxisSize: MainAxisSize.min,
                    children: \[
                      IconButton\(icon: const Icon\(Icons.print, color: Colors.blueGrey, size: 20\), tooltip: 'Print Purchase', onPressed: \(\) async \{
                        final options = await PrintDialog.show\(context, defaultLanguageCode: Localizations.localeOf\(context\).languageCode\);
                        if \(options != null && context.mounted\) \{
                          Navigator.push\(context, MaterialPageRoute\(builder: \(_\) => PdfPreviewScreen\(title: "Purchase \$\{pur.purchaseNumber\}", buildPdf: \(\) => ref.read\(pdfGeneratorProvider\).generatePurchasePdf\(pur.id, options\)\)\)\);
                        \}
                      \}\),
                      
                        IconButton\(icon: const Icon\(Icons.attach_money, color: Colors.green, size: 20\), tooltip: 'Record Payment', onPressed: \(\) \{
                          PaymentDialog.show\(context, entityId: pur.id, entityType: 'PURCHASE', partnerId: widget.id, currentTotal: pur.total, currentlyPaid: pur.paidAmount\);
                        \}\),
                      IconButton\(icon: const Icon\(Icons.receipt_long, color: Colors.teal, size: 20\), tooltip: 'View Payments & Checks', onPressed: \(\) \{
                        ViewPaymentsDialog.show\(context, entityId: pur.id, entityType: 'PURCHASE'\);
                      \}\),
                      if \(ref.watch\(currentUserProvider\)\?.role == 'ADMIN'\)
                         IconButton\(icon: const Icon\(Icons.delete, color: Colors.red, size: 20\), onPressed: \(\) async \{
                             final userId = ref.read\(currentUserProvider\)\?.id \?\? '';
                             await ref.read\(purchaseServiceProvider\).deletePurchase\(pur.id, userId\);
                         \}\),
                    \]
                  \),"""

new_pur_trailing = r"""                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'print') {
                        final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                        if (options != null && context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Purchase ${pur.purchaseNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generatePurchasePdf(pur.id, options))));
                        }
                      } else if (value == 'record_payment') {
                        PaymentDialog.show(context, entityId: pur.id, entityType: 'PURCHASE', partnerId: widget.id, currentTotal: pur.total, currentlyPaid: pur.paidAmount);
                      } else if (value == 'view_payments') {
                        ViewPaymentsDialog.show(context, entityId: pur.id, entityType: 'PURCHASE');
                      } else if (value == 'delete') {
                        final userId = ref.read(currentUserProvider)?.id ?? '';
                        await ref.read(purchaseServiceProvider).deletePurchase(pur.id, userId);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'print', child: Text(AppLocalizations.of(context)?.printDocument ?? 'Print')),
                      PopupMenuItem(value: 'record_payment', child: Text(AppLocalizations.of(context)?.recordPayment ?? 'Record Payment')),
                      PopupMenuItem(value: 'view_payments', child: Text(AppLocalizations.of(context)?.viewPaymentsChecks ?? 'View Payments')),
                      if (ref.watch(currentUserProvider)?.role == 'ADMIN')
                        PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)?.deleteStr ?? 'Delete', style: const TextStyle(color: Colors.red))),
                    ],
                  ),"""

content = re.sub(old_pur_trailing, new_pur_trailing, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Replaced inline IconButtons with PopupMenuButton")
