import re

# 1. products_screen.dart translations
f = 'lib/src/presentation/products/products_screen.dart'
with open(f, 'r') as file: content = file.read()
content = content.replace("Text('Create Consumables')", "Text(AppLocalizations.of(context)!.createConsumables)")
content = content.replace("Text('Add Family Member')", "Text(AppLocalizations.of(context)!.addFamilyMember)")
content = content.replace("Text('Edit')", "Text(AppLocalizations.of(context)!.edit)")
content = content.replace("Text('Delete', style: TextStyle(color: Colors.red))", "Text(AppLocalizations.of(context)!.deleteStr, style: const TextStyle(color: Colors.red))")
with open(f, 'w') as file: file.write(content)

# 2. clients_screen.dart translations
f = 'lib/src/presentation/clients/clients_screen.dart'
with open(f, 'r') as file: content = file.read()
content = content.replace("Text('Ledger / Payments')", "Text(AppLocalizations.of(context)!.ledgerPayments)")
content = content.replace("Text('Edit')", "Text(AppLocalizations.of(context)!.edit)")
content = content.replace("Text('Delete', style: TextStyle(color: Colors.red))", "Text(AppLocalizations.of(context)!.deleteStr, style: const TextStyle(color: Colors.red))")
with open(f, 'w') as file: file.write(content)

# 3. suppliers_screen.dart translations
f = 'lib/src/presentation/suppliers/suppliers_screen.dart'
with open(f, 'r') as file: content = file.read()
content = content.replace("Text('Ledger / Payments')", "Text(AppLocalizations.of(context)!.ledgerPayments)")
content = content.replace("Text('Edit')", "Text(AppLocalizations.of(context)!.edit)")
content = content.replace("Text('Delete', style: TextStyle(color: Colors.red))", "Text(AppLocalizations.of(context)!.deleteStr, style: const TextStyle(color: Colors.red))")
with open(f, 'w') as file: file.write(content)

# 4. documents_screen.dart translations
f = 'lib/src/presentation/documents/documents_screen.dart'
with open(f, 'r') as file: content = file.read()
content = content.replace("Text('Print Document')", "Text(AppLocalizations.of(context)!.printDocument)")
content = content.replace("Text('Record Payment')", "Text(AppLocalizations.of(context)!.recordPayment)")
content = content.replace("Text('View Payments & Checks')", "Text(AppLocalizations.of(context)!.viewPaymentsChecks)")
content = content.replace("Text('Delete', style: TextStyle(color: Colors.red))", "Text(AppLocalizations.of(context)!.deleteStr, style: const TextStyle(color: Colors.red))")
with open(f, 'w') as file: file.write(content)

# 5. Dashboard and Stock
f = 'lib/src/presentation/dashboard/dashboard_screen.dart'
with open(f, 'r') as file: content = file.read()
content = content.replace("'Dashboard'", "AppLocalizations.of(context)!.dashboardTitle")
content = content.replace("'Total Sales'", "AppLocalizations.of(context)!.totalSalesLabel")
content = content.replace("'Total Purchases'", "AppLocalizations.of(context)!.totalPurchasesLabel")
content = content.replace("'Cash in Register'", "AppLocalizations.of(context)!.cashInRegisterLabel")
content = content.replace("'Recent Transactions'", "AppLocalizations.of(context)!.recentTransactionsLabel")
with open(f, 'w') as file: file.write(content)

f = 'lib/src/presentation/stock/stock_screen.dart'
with open(f, 'r') as file: content = file.read()
content = content.replace("'Stock'", "AppLocalizations.of(context)!.stockTitle")
content = content.replace("'Products:'", "AppLocalizations.of(context)!.products")
with open(f, 'w') as file: file.write(content)

# 6. Add Product Screen
f = 'lib/src/presentation/products/add_product_screen.dart'
with open(f, 'r') as file: content = file.read()
content = content.replace("labelText: 'Name'", "labelText: AppLocalizations.of(context)!.productNameLabel")
content = content.replace("labelText: 'Reference'", "labelText: AppLocalizations.of(context)!.referenceLabel")
content = content.replace("labelText: 'Purchase Price'", "labelText: AppLocalizations.of(context)!.purchasePriceLabel")
content = content.replace("labelText: 'Selling Price'", "labelText: AppLocalizations.of(context)!.sellingPriceLabel")
content = content.replace("labelText: 'Tier 2 Price'", "labelText: AppLocalizations.of(context)!.tier2PriceLabel")
content = content.replace("labelText: 'Tier 3 Price'", "labelText: AppLocalizations.of(context)!.tier3PriceLabel")
content = content.replace("labelText: 'Packaging'", "labelText: AppLocalizations.of(context)!.packagingLabel")
content = content.replace("labelText: 'Base Min Stock'", "labelText: AppLocalizations.of(context)!.baseMinStockLabel")
content = content.replace("labelText: 'Magazin Min Stock'", "labelText: AppLocalizations.of(context)!.magazinMinStockLabel")
content = content.replace("labelText: 'Arabic Tag'", "labelText: AppLocalizations.of(context)!.arabicTagLabel")
content = content.replace("labelText: 'French Tag'", "labelText: AppLocalizations.of(context)!.frenchTagLabel")
content = content.replace("labelText: 'Spanish Tag'", "labelText: AppLocalizations.of(context)!.spanishTagLabel")
content = content.replace("labelText: 'Unit Size'", "labelText: AppLocalizations.of(context)!.unitSizeLabel")
content = content.replace("labelText: 'Units Per Box'", "labelText: AppLocalizations.of(context)!.unitsPerBoxLabel")
content = content.replace("Text('Unit Type:')", "Text('${AppLocalizations.of(context)!.unitTypeLabel}:')")
with open(f, 'w') as file: file.write(content)

# 7. Check History Clickable Image
f = 'lib/src/presentation/widgets/human_profile_dialog.dart'
with open(f, 'r') as file: content = file.read()

# Replace ListTile in _buildChecksTab to add onTap
old_list_tile = r"return ListTile\(\s*leading: CircleAvatar\("
new_list_tile = r"""return ListTile(
              onTap: payment.method == 'CHECK' && payment.checkImagePath != null && payment.checkImagePath!.isNotEmpty
                  ? () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          content: Image.file(File(payment.checkImagePath!)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                          ],
                        ),
                      );
                    }
                  : null,
              leading: CircleAvatar("""
content = re.sub(old_list_tile, new_list_tile, content)
with open(f, 'w') as file: file.write(content)

print("UI updated.")
