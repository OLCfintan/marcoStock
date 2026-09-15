import 'dart:convert';
import 'dart:io';

void main() async {
  final keys = {
    "paymentExceedsTotal": "Payment amount cannot exceed the total.",
    "walkInClient": "Client Passager",
    "edit": "Edit",
    "confirmReturn": "CONFIRM RETURN",
    "processReturn": "Process Return",
    "garbage": "Garbage / Deleted",
    "recordPurchase": "RECORD PURCHASE",
    "recordInboundPurchase": "Record Inbound Purchase (ACH)",
    "returnCompletedSuccessfully": "Return completed successfully!",
    "employees": "Employees"
  };

  final dir = Directory('lib/src/localization/arb');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb'));

  for (final file in files) {
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    
    for (final entry in keys.entries) {
      if (!json.containsKey(entry.key)) {
        json[entry.key] = entry.value;
      }
    }

    final encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(json)}\n');
    print('Updated ${file.path}');
  }
}
