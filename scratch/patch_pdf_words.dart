import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  // Replace decimalToWordsFrench usage
  content = content.replaceAll(
    "final amountWords = decimalToWordsFrench(invoice.total.toDouble(), 'dirhams', 'centimes');",
    "final amountWords = decimalToWordsTranslated(invoice.total.toDouble(), l10n.localeName);"
  );
  
  // Replace Arrêté la présente facture...
  content = content.replaceAll(
    "child: _bidiText('Arrêté la présente facture à la somme de : \${amountWords.substring(0,1).toUpperCase() + amountWords.substring(1)}.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),",
    "child: _bidiText('\${l10n.invoiceStoppedAt} \${amountWords.substring(0,1).toUpperCase() + amountWords.substring(1)}.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),"
  );
  
  file.writeAsStringSync(content);
}
