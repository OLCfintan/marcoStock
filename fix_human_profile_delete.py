import re

filepath = "lib/src/presentation/widgets/human_profile_dialog.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Add SalesService and PurchaseService imports if needed
if "import '../../application/sales/sales_service.dart';" not in content:
    content = "import '../../application/sales/sales_service.dart';\n" + content
if "import '../../application/purchases/purchase_service.dart';" not in content:
    content = "import '../../application/purchases/purchase_service.dart';\n" + content
if "import '../../application/auth/auth_providers.dart';" not in content:
    content = "import '../../application/auth/auth_providers.dart';\n" + content


# Fix invoice delete
old_inv_delete = r"""                             await \(db.update\(db.invoices\)\.\.where\(\(t\) => t.id.equals\(inv.id\)\)\).write\(const InvoicesCompanion\(isActive: drift.Value\(false\)\)\);"""
new_inv_delete = r"""                             final userId = ref.read(currentUserProvider)?.id ?? '';
                             await ref.read(salesServiceProvider).deleteInvoice(inv.id, userId);"""
content = re.sub(old_inv_delete, new_inv_delete, content)

# Fix purchase delete
old_pur_delete = r"""                             await \(db.update\(db.purchases\)\.\.where\(\(t\) => t.id.equals\(pur.id\)\)\).write\(const PurchasesCompanion\(isActive: drift.Value\(false\)\)\);"""
new_pur_delete = r"""                             final userId = ref.read(currentUserProvider)?.id ?? '';
                             await ref.read(purchaseServiceProvider).deletePurchase(pur.id, userId);"""
content = re.sub(old_pur_delete, new_pur_delete, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Fixed human profile dialog delete")
