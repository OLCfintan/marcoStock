import re

with open('lib/src/application/purchases/purchase_service.dart', 'r') as f:
    purchase = f.read()

# Fix WAC
purchase = purchase.replace('totalOldBaseQty += pQty * p.unitSize;', '''final pBase = await getDeterministicBaseProduct(_db, p);
          totalOldBaseQty += convertQuantityToBase(pQty, p, pBase);''')

purchase = purchase.replace('final addedBaseQty = line.quantity * product.unitSize;', '''final baseProductForWac = await getDeterministicBaseProduct(_db, product);
        final addedBaseQty = convertQuantityToBase(line.quantity, product, baseProductForWac);''')

# Fix deletePurchase
purchase = purchase.replace('final totalBaseUnits = line.quantity * product.unitSize;', 'final totalBaseUnits = convertQuantityToBase(line.quantity, product, baseProduct);')

# Fix _addStock
purchase = purchase.replace('final totalBaseUnits = quantity * product.unitSize;', 'final totalBaseUnits = convertQuantityToBase(quantity, product, baseProduct);')

with open('lib/src/application/purchases/purchase_service.dart', 'w') as f:
    f.write(purchase)


with open('lib/src/application/sales/sales_service.dart', 'r') as f:
    sales = f.read()

sales = sales.replace('Decimal actualQuantityToDeduct = quantity * product.unitSize;', 'Decimal actualQuantityToDeduct = convertQuantityToBase(quantity, product, baseProduct);')
sales = sales.replace('Decimal actualQtyToAdd = quantity * product.unitSize;', 'Decimal actualQtyToAdd = convertQuantityToBase(quantity, product, baseProduct);')

with open('lib/src/application/sales/sales_service.dart', 'w') as f:
    f.write(sales)


with open('lib/src/application/stock/stock_transfer_service.dart', 'r') as f:
    transfer = f.read()

transfer = transfer.replace('final totalBaseUnits = quantity * unitSize;', 'final totalBaseUnits = convertQuantityToBase(quantity, product, baseProduct);')

with open('lib/src/application/stock/stock_transfer_service.dart', 'w') as f:
    f.write(transfer)

