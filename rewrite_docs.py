with open("lib/src/presentation/documents/documents_screen.dart", "r") as f:
    lines = f.readlines()

out = []
skip = False
for line in lines:
    if "trailing: Row(" in line and "mainAxisSize: MainAxisSize.min" in lines[lines.index(line)+1]:
        # we found a trailing Row block.
        skip = True
        
        # Check if it's invoice or purchase based on surrounding context (e.g. invoice.documentType)
        # We can just look ahead to see what it is
        idx = lines.index(line)
        block = "".join(lines[idx:idx+30])
        if "invoice.documentType" in block:
            out.append("""                        trailing: PopupMenuButton<String>(
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
                        ),
""")
        else:
            out.append("""                      trailing: PopupMenuButton<String>(
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
                      ),
""")
        continue
    
    if skip:
        # look for the closing bracket of the Row
        if "]," in line and "}" not in line: # wait, the closing bracket is ], followed by ),
            pass
        if "), " in line or ")," in line:
            # check if it closes the Row. actually let's just use strict line numbers
            pass
            
# Since parsing curly braces in python is hard, let's just use line ranges!
