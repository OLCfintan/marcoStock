import re

with open('lib/src/application/payments/payment_service.dart', 'r') as f:
    content = f.read()

# Fix client
content = content.replace(
    "..where((t) => t.clientId.equals(payment.clientId!) & t.isActive.equals(true) & t.paidAmount.isBiggerThanValue(Decimal.zero))",
    "..where((t) => t.clientId.equals(payment.clientId!) & t.isActive.equals(true))"
)
content = content.replace(
    "for (final inv in paidInvoices) {",
    "for (final inv in paidInvoices) {\n              if (inv.paidAmount <= Decimal.zero) continue;"
)

# Fix supplier
content = content.replace(
    "..where((t) => t.supplierId.equals(payment.supplierId!) & t.isActive.equals(true) & t.paidAmount.isBiggerThanValue(Decimal.zero))",
    "..where((t) => t.supplierId.equals(payment.supplierId!) & t.isActive.equals(true))"
)
content = content.replace(
    "for (final pur in paidPurchases) {",
    "for (final pur in paidPurchases) {\n              if (pur.paidAmount <= Decimal.zero) continue;"
)


with open('lib/src/application/payments/payment_service.dart', 'w') as f:
    f.write(content)
