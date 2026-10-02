import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE invoices (
      invoice_number TEXT
    );
  ''');
  
  db.execute("INSERT INTO invoices (invoice_number) VALUES ('MG1')");
  
  final result = db.select("SELECT invoice_number FROM invoices WHERE invoice_number LIKE 'MG%' ORDER BY LENGTH(invoice_number) DESC, invoice_number DESC LIMIT 1");
  print(result);
  
  db.execute("INSERT INTO invoices (invoice_number) VALUES ('MG2')");
  final result2 = db.select("SELECT invoice_number FROM invoices WHERE invoice_number LIKE 'MG%' ORDER BY LENGTH(invoice_number) DESC, invoice_number DESC LIMIT 1");
  print(result2);

  db.execute("INSERT INTO invoices (invoice_number) VALUES ('MG10')");
  final result3 = db.select("SELECT invoice_number FROM invoices WHERE invoice_number LIKE 'MG%' ORDER BY LENGTH(invoice_number) DESC, invoice_number DESC LIMIT 1");
  print(result3);
  
  db.execute("INSERT INTO invoices (invoice_number) VALUES ('MG20508')");
  final result4 = db.select("SELECT invoice_number FROM invoices WHERE invoice_number LIKE 'MG%' ORDER BY LENGTH(invoice_number) DESC, invoice_number DESC LIMIT 1");
  print(result4);

}
