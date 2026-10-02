import re

with open('lib/src/application/sales/sales_service.dart', 'r') as f:
    content = f.read()

old_req = """class SaleRequest {
  final String documentType;
  final String clientId;
  final String currentUserId;
  final List<SaleLineRequest> lines;
  final List<SalePaymentRequest> payments;
  final String notes;
  final DateTime? customDate;
  final String? customInvoiceNumber;

  SaleRequest({
    required this.documentType,
    required this.clientId,
    required this.currentUserId,
    required this.lines,
    required this.payments,
    this.notes = '',
    this.customDate,
    this.customInvoiceNumber,
  });
}"""

new_req = """class SaleRequest {
  final String documentType;
  final String clientId;
  final String currentUserId;
  final List<SaleLineRequest> lines;
  final List<SalePaymentRequest> payments;
  final String notes;
  final DateTime? customDate;
  final String? customInvoiceNumber;
  final String companyBranch;

  SaleRequest({
    required this.documentType,
    required this.clientId,
    required this.currentUserId,
    required this.lines,
    required this.payments,
    this.notes = '',
    this.customDate,
    this.customInvoiceNumber,
    this.companyBranch = 'MARKO_GROUP',
  });
}"""
content = content.replace(old_req, new_req)

old_ins = """        status: status,
        paymentMethod: drift.Value(paymentMethodStr),
      ));"""
new_ins = """        status: status,
        paymentMethod: drift.Value(paymentMethodStr),
        companyBranch: drift.Value(request.companyBranch),
      ));"""
content = content.replace(old_ins, new_ins)

with open('lib/src/application/sales/sales_service.dart', 'w') as f:
    f.write(content)
print("patched sales service properly")
