import re

filepath = "lib/src/application/sales/sales_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_restore = r"""        // Re-apply Stock Deduction
        await _deductStock\(
          productId: line.productId,
          quantity: line.quantity,
          reason: 'SALE_RESTORED',
          allowNegative: true,
          referenceOperationId: invoiceId,
          userId: userId,
          locationId: locationId,
        \);



        // Re-apply Consumables Deduction"""

new_restore = r"""        // Re-apply Stock Deduction
        await _deductStock(
          productId: line.productId,
          quantity: line.quantity,
          reason: 'SALE_RESTORED',
          allowNegative: true,
          referenceOperationId: invoiceId,
          userId: userId,
          locationId: locationId,
        );

        // Re-apply Magazin transfer if special client
        if ((client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01')) {
          await _restoreStock(
            productId: line.productId,
            quantity: line.quantity,
            reason: 'TRANSFER_IN_RESTORED',
            referenceOperationId: invoiceId,
            userId: userId,
            locationId: AppLocations.magazin,
          );
        }

        // Re-apply Consumables Deduction"""

content = re.sub(old_restore, new_restore, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Fixed restoreInvoice in SalesService")
