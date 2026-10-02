import 'dart:io';

void main() {
  // Let's just output the query used
  print("SELECT invoice_number FROM invoices WHERE invoice_number LIKE '\$prefix%' ORDER BY LENGTH(invoice_number) DESC, invoice_number DESC LIMIT 1");
}
