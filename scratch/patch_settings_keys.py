import re

with open('lib/src/application/settings/settings_service.dart', 'r') as f:
    content = f.read()

old_keys = """    final keys = ['companyName', 'companyAddress', 'companyPhone', 'companyTaxId', 'companyTaxRate', 'companyLogoPath', 'invoiceCounterPrefix', 'companyIce', 'companyRc', 'companyRib', 'companyEmail'];"""
new_keys = """    final keys = ['companyName', 'companyAddress', 'companyInvoiceAddress', 'companyTp', 'companyPhone', 'companyTaxId', 'companyTaxRate', 'companyLogoPath', 'invoiceCounterPrefix', 'companyIce', 'companyRc', 'companyRib', 'companyEmail'];"""
content = content.replace(old_keys, new_keys)

with open('lib/src/application/settings/settings_service.dart', 'w') as f:
    f.write(content)
print("Settings keys patched")
