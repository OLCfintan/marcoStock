with open('lib/src/presentation/documents/documents_screen.dart', 'r') as f:
    content = f.read()
content = content.replace("await onEditInvoice(invoice, client, ref.read(databaseProvider));", "await onEditPurchase(purchase, supplier, ref.read(databaseProvider));", 2)
content = content.replace("await onEditPurchase(purchase, supplier, ref.read(databaseProvider));", "await onEditInvoice(invoice, client, ref.read(databaseProvider));", 1)
with open('lib/src/presentation/documents/documents_screen.dart', 'w') as f:
    f.write(content)
