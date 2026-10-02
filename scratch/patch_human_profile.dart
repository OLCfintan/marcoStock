import 'dart:io';

void main() {
  final file = File('lib/src/presentation/widgets/human_profile_dialog.dart');
  var content = file.readAsStringSync();
  
  // Replace the title of the list tile to show documentType and override name
  content = content.replaceFirst(
    "title: Text('Invoice #\${inv.invoiceNumber}'),",
    "title: Text('\${inv.documentType == 'FACTURE_DUMMY' ? 'FACTURE' : inv.documentType} #\${inv.invoiceNumber}' + (inv.clientNameOverride != null && inv.clientNameOverride!.isNotEmpty ? ' - \${inv.clientNameOverride}' : '')),"
  );
  
  content = content.replaceFirst(
    "title: Text('Purchase #\${inv.purchaseNumber}'),",
    "title: Text('Purchase #\${inv.purchaseNumber}'),"
  );
  
  file.writeAsStringSync(content);
}
