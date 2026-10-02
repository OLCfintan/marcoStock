import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# 1. Update exportAndSharePdf to read new settings
old_load = """    final companyAddress = settings['companyAddress'] ?? '';
    final companyPhone = settings['companyPhone'] ?? '';
    final companyTaxId = settings['companyTaxId'] ?? '';"""
new_load = """    final companyAddress = settings['companyAddress'] ?? '';
    final companyInvoiceAddress = settings['companyInvoiceAddress'] ?? companyAddress;
    final companyPhone = settings['companyPhone'] ?? '';
    final companyTaxId = settings['companyTaxId'] ?? '';
    final companyTp = settings['companyTp'] ?? '';"""
content = content.replace(old_load, new_load)

# Pass new fields to _buildFactureHeader, _buildOldHeader, _buildFactureFooter, _buildOldFooter, etc.
# Wait, they might already accept strings. Let's see their signatures.
