import re

with open('lib/src/application/sales/sales_service.dart', 'r') as f:
    content = f.read()

old_ins = """        total: total,
        paidAmount: paidAmount,
        status: status,
      ));"""

new_ins = """        total: total,
        paidAmount: paidAmount,
        status: status,
        companyBranch: drift.Value(request.companyBranch),
        paymentMethod: drift.Value(request.payments.isNotEmpty ? request.payments.first.method : null),
      ));"""

content = content.replace(old_ins, new_ins)

with open('lib/src/application/sales/sales_service.dart', 'w') as f:
    f.write(content)
print("patched executeSale properly")
