import re

with open('lib/src/application/sales/sales_service.dart', 'r') as f:
    content = f.read()

# createInvoice
old_sig = """    bool isTempClient = false,
    String documentType = 'FACTURE',
    String? paymentMethod,
  }) async {"""
new_sig = """    bool isTempClient = false,
    String documentType = 'FACTURE',
    String? paymentMethod,
    String companyBranch = 'MARKO_GROUP',
  }) async {"""
content = content.replace(old_sig, new_sig)

old_insert = """        paidAmount: DecimalConverter().toSql(paidAmount),
        status: status,
        paymentMethod: Value(paymentMethod),
      ));"""
new_insert = """        paidAmount: DecimalConverter().toSql(paidAmount),
        status: status,
        paymentMethod: Value(paymentMethod),
        companyBranch: Value(companyBranch),
      ));"""
content = content.replace(old_insert, new_insert)

with open('lib/src/application/sales/sales_service.dart', 'w') as f:
    f.write(content)
print("sales_service patched")
