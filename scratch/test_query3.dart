import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE invoices (
      invoice_number TEXT
    );
  ''');
  
  db.execute("INSERT INTO invoices (invoice_number) VALUES ('MG-20508')");
  db.execute("INSERT INTO invoices (invoice_number) VALUES ('MG-20507')");
  
  final result = db.select("SELECT invoice_number FROM invoices WHERE invoice_number LIKE 'MG%' ORDER BY LENGTH(invoice_number) DESC, invoice_number DESC LIMIT 1");
  print(result);
}
