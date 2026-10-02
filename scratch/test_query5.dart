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
  db.execute("INSERT INTO invoices (invoice_number) VALUES ('MG10')");
  db.execute("INSERT INTO invoices (invoice_number) VALUES ('MG20508')");
  db.execute("INSERT INTO invoices (invoice_number) VALUES ('MG20509')");
  db.execute("INSERT INTO invoices (invoice_number) VALUES ('MG-20508')");
  
  final prefix = 'MG';
  final len = prefix.length + 1;
  final query = "SELECT CAST(SUBSTR(invoice_number, $len) AS INTEGER) AS num FROM invoices WHERE invoice_number LIKE '$prefix%' ORDER BY num DESC LIMIT 1";
  final result = db.select(query);
  print(result);
}
