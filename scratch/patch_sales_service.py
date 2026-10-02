import re

with open('lib/src/application/sales/sales_service.dart', 'r') as f:
    content = f.read()

# Update signature
old_sig = """  Future<String> createInvoice({
    required String? clientId,
    required List<SaleLineRequest> lines,
    required List<PaymentRequest> payments,
    required String userId,
    bool isTempClient = false,
    String documentType = 'FACTURE',
  }) async {"""

new_sig = """  Future<String> createInvoice({
    required String? clientId,
    required List<SaleLineRequest> lines,
    required List<PaymentRequest> payments,
    required String userId,
    bool isTempClient = false,
    String documentType = 'FACTURE',
    String? paymentMethod,
  }) async {"""
content = content.replace(old_sig, new_sig)

# Save to invoice
old_insert = """      await _db.into(_db.invoices).insert(InvoicesCompanion.insert(
        id: invoiceId,
        invoiceNumber: invoiceNum,
        documentType: Value(documentType),
        clientId: Value(clientId),
        date: now,
        subtotal: DecimalConverter().toSql(totalLineAmount),
        taxes: DecimalConverter().toSql(taxes),
        total: DecimalConverter().toSql(finalTotal),
        paidAmount: DecimalConverter().toSql(totalPaid),
        status: status,
      ));"""

new_insert = """      await _db.into(_db.invoices).insert(InvoicesCompanion.insert(
        id: invoiceId,
        invoiceNumber: invoiceNum,
        documentType: Value(documentType),
        clientId: Value(clientId),
        date: now,
        subtotal: DecimalConverter().toSql(totalLineAmount),
        taxes: DecimalConverter().toSql(taxes),
        total: DecimalConverter().toSql(finalTotal),
        paidAmount: DecimalConverter().toSql(totalPaid),
        status: status,
        paymentMethod: Value(paymentMethod),
      ));"""
content = content.replace(old_insert, new_insert)

with open('lib/src/application/sales/sales_service.dart', 'w') as f:
    f.write(content)
print("sales_service.dart patched")
