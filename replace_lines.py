with open("lib/src/presentation/documents/documents_screen.dart", "r") as f:
    lines = f.readlines()

new_invoice_block = """                        trailing: PopupMenuButton<String>(
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
                            if (ref.watch(currentUserProvider)?.role == 'ADMIN')
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
"""

new_purchase_block = """                      trailing: PopupMenuButton<String>(
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
                          if (ref.watch(currentUserProvider)?.role == 'ADMIN')
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
"""

# Replace lines 215-233 first (so we don't mess up invoice indices)
out = lines[:214] + [new_purchase_block] + lines[233:]

# Then replace lines 128-175
out = out[:127] + [new_invoice_block] + out[175:]

with open("lib/src/presentation/documents/documents_screen.dart", "w") as f:
    f.writelines(out)
