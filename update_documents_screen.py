import re

filepath = "lib/src/presentation/documents/documents_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Tab 1: INVOICES
old_invoice_trailing = r"""                        trailing: Row\(
                          mainAxisSize: MainAxisSize\.min,
                          children: \[
                            IconButton\(icon: const Icon\(Icons\.print, color: Colors\.blueGrey\), tooltip: 'View/Print Document', onPressed: \(\) \{
                              Navigator\.push\(context, MaterialPageRoute\(
                                builder: \(\_\) => PdfPreviewScreen\(
                                  title: '\$\{invoice\.documentType\} #\$\{invoice\.invoiceNumber\}',
                                  buildPdf: \(\) => ref\.read\(pdfGeneratorProvider\)\.generateInvoicePdf\(invoice\.id, AppLocalizations\.of\(context\)!\),
                                \),
                              \)\);
                            \}\),
                          IconButton\(icon: const Icon\(Icons\.attach_money, color: Colors\.green\), tooltip: 'Record Payment', onPressed: \(\) \{
                            PaymentDialog\.show\(context, entityId: invoice\.id, entityType: 'INVOICE', partnerId: client\?\.id, currentTotal: invoice\.total, currentlyPaid: invoice\.paidAmount\);
                          \}\),
                          IconButton\(icon: const Icon\(Icons\.receipt_long, color: Colors\.blue\), tooltip: 'View Payments & Checks', onPressed: \(\) \{
                            ViewPaymentsDialog\.show\(context, entityId: invoice\.id, entityType: 'INVOICE'\);
                          \}\),
                          if \(invoice\.documentType == 'BON'\)
                            IconButton\(
                              icon: const Icon\(Icons\.transform, color: Colors\.purple\),
                              tooltip: AppLocalizations\.of\(context\)!\.convertToInvoice,
                              onPressed: \(\) async \{
                                final confirm = await showDialog<bool>\(
                                  context: context,
                                  builder: \(ctx\) => AlertDialog\(
                                    title: Text\(AppLocalizations\.of\(context\)!\.convertToInvoice\),
                                    content: Text\(AppLocalizations\.of\(context\)!\.convertBonToInvoice\),
                                    actions: \[
                                      TextButton\(onPressed: \(\) => Navigator\.pop\(ctx, false\), child: Text\(AppLocalizations\.of\(context\)!\.cancel\)\),
                                      TextButton\(onPressed: \(\) => Navigator\.pop\(ctx, true\), child: Text\(AppLocalizations\.of\(context\)!\.confirm\)\),
                                    \],
                                  \),
                                \);
                                if \(confirm == true\) \{
                                  await ref\.read\(salesServiceProvider\)\.convertBonToInvoice\(invoice\.id\);
                                  if \(context\.mounted\) \{
                                    ScaffoldMessenger\.of\(context\)\.showSnackBar\(SnackBar\(content: Text\(AppLocalizations\.of\(context\)!\.convertedSuccessfully\)\)\);
                                  \}
                                \}
                              \}
                            \),
                          if \(ref\.watch\(currentUserProvider\)\?\.role == 'ADMIN'\)
                            IconButton\(icon: const Icon\(Icons\.delete, color: Colors\.red\), onPressed: \(\) async \{
                              final userId = ref\.read\(currentUserProvider\)\?\.id ?? '';
                              await ref\.read\(salesServiceProvider\)\.deleteInvoice\(invoice\.id, userId\);
                            \}\),
                        \],
                      \),"""

new_invoice_trailing = r"""                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            if (value == 'print') {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => PdfPreviewScreen(
                                  title: '${invoice.documentType} #${invoice.invoiceNumber}',
                                  buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(invoice.id, AppLocalizations.of(context)!),
                                ),
                              ));
                            } else if (value == 'record_payment') {
                              PaymentDialog.show(context, entityId: invoice.id, entityType: 'INVOICE', partnerId: client?.id, currentTotal: invoice.total, currentlyPaid: invoice.paidAmount);
                            } else if (value == 'view_payments') {
                              ViewPaymentsDialog.show(context, entityId: invoice.id, entityType: 'INVOICE');
                            } else if (value == 'convert') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(AppLocalizations.of(context)!.convertToInvoice),
                                    content: Text(AppLocalizations.of(context)!.convertBonToInvoice),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.confirm)),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(salesServiceProvider).convertBonToInvoice(invoice.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.convertedSuccessfully)));
                                  }
                                }
                            } else if (value == 'delete') {
                              final userId = ref.read(currentUserProvider)?.id ?? '';
                              await ref.read(salesServiceProvider).deleteInvoice(invoice.id, userId);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'print', child: Text('Print Document')),
                            const PopupMenuItem(value: 'record_payment', child: Text('Record Payment')),
                            const PopupMenuItem(value: 'view_payments', child: Text('View Payments & Checks')),
                            if (invoice.documentType == 'BON')
                              PopupMenuItem(value: 'convert', child: Text(AppLocalizations.of(context)!.convertToInvoice)),
                            if (ref.read(currentUserProvider)?.role == 'ADMIN')
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),"""

content = re.sub(old_invoice_trailing, new_invoice_trailing, content, flags=re.MULTILINE | re.DOTALL)


# Tab 2: PURCHASES
old_purchase_trailing = r"""                      trailing: Row\(
                        mainAxisSize: MainAxisSize\.min,
                        children: \[
                          IconButton\(icon: const Icon\(Icons\.print, color: Colors\.blueGrey\), tooltip: 'Print Document', onPressed: \(\) \{
                            Navigator\.push\(context, MaterialPageRoute\(builder: \(\_\) => PdfPreviewScreen\(title: "Purchase \$\{purchase\.purchaseNumber\}", buildPdf: \(\) => ref\.read\(pdfGeneratorProvider\)\.generatePurchasePdf\(purchase\.id, AppLocalizations\.of\(context\)!\)\)\)\);
                          \}\),
                          IconButton\(icon: const Icon\(Icons\.attach_money, color: Colors\.green\), tooltip: 'Record Payment', onPressed: \(\) \{
                            PaymentDialog\.show\(context, entityId: purchase\.id, entityType: 'PURCHASE', partnerId: supplier\?\.id, currentTotal: purchase\.total, currentlyPaid: purchase\.paidAmount\);
                          \}\),
                          IconButton\(icon: const Icon\(Icons\.receipt_long, color: Colors\.blue\), tooltip: 'View Payments & Checks', onPressed: \(\) \{
                            ViewPaymentsDialog\.show\(context, entityId: purchase\.id, entityType: 'PURCHASE'\);
                          \}\),
                          if \(ref\.watch\(currentUserProvider\)\?\.role == 'ADMIN'\)
                            IconButton\(icon: const Icon\(Icons\.delete, color: Colors\.red\), onPressed: \(\) async \{
                              final userId = ref\.read\(currentUserProvider\)\?\.id ?? '';
                              await ref\.read\(purchaseServiceProvider\)\.deletePurchase\(purchase\.id, userId\);
                            \}\),
                        \],
                      \),"""

new_purchase_trailing = r"""                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'print') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Purchase ${purchase.purchaseNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generatePurchasePdf(purchase.id, AppLocalizations.of(context)!))));
                          } else if (value == 'record_payment') {
                            PaymentDialog.show(context, entityId: purchase.id, entityType: 'PURCHASE', partnerId: supplier?.id, currentTotal: purchase.total, currentlyPaid: purchase.paidAmount);
                          } else if (value == 'view_payments') {
                            ViewPaymentsDialog.show(context, entityId: purchase.id, entityType: 'PURCHASE');
                          } else if (value == 'delete') {
                            final userId = ref.read(currentUserProvider)?.id ?? '';
                            await ref.read(purchaseServiceProvider).deletePurchase(purchase.id, userId);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'print', child: Text('Print Document')),
                          const PopupMenuItem(value: 'record_payment', child: Text('Record Payment')),
                          const PopupMenuItem(value: 'view_payments', child: Text('View Payments & Checks')),
                          if (ref.read(currentUserProvider)?.role == 'ADMIN')
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),"""

content = re.sub(old_purchase_trailing, new_purchase_trailing, content, flags=re.MULTILINE | re.DOTALL)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
