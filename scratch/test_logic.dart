void main() {
  Map<String, String> companySettings = {
    'companyAddress': 'Bons Address',
  };
  
  final companyAddress = companySettings['companyAddress'] ?? '';
  final companyInvoiceAddress = companySettings['companyInvoiceAddress'] ?? companyAddress;
  
  print('Invoice Address: $companyInvoiceAddress');
}
