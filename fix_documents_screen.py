import re

filepath = "lib/src/presentation/documents/documents_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Tab 1: INVOICES
old_invoice_pattern = r"trailing:\s*Row\(\s*mainAxisSize:\s*MainAxisSize\.min,\s*children:\s*\[.*?IconButton\(.*?IconButton\(.*?IconButton\(.*?IconButton\(.*?\]\s*,\s*\),"
new_invoice = r"""                        trailing: PopupMenuButton<String>(
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

content = re.sub(r"trailing:\s*Row\(\s*mainAxisSize:\s*MainAxisSize\.min,\s*children:\s*\[.*?IconButton\(.*?IconButton\(.*?IconButton\(.*?IconButton\(.*?\]\s*,\s*\),", new_invoice, content, flags=re.MULTILINE | re.DOTALL)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
