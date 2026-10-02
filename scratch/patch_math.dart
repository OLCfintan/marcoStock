import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  final target = '''
    final amountWords = decimalToWordsTranslated(invoice.total.toDouble(), l10n.localeName);
    
    // Facture Math logic
    final totalTtc = invoice.total.toDouble();
    final mtHt = totalTtc / 1.20;
    final mtTva = mtHt * 0.20;''';
    
  final replacement = '''
    // Facture Math logic
    final mtHt = invoice.total.toDouble();
    final mtTva = mtHt * 0.20;
    final totalTtc = mtHt + mtTva;
    
    final amountWords = decimalToWordsTranslated(totalTtc, l10n.localeName);''';
    
  if (content.contains(target)) {
    content = content.replaceFirst(target, replacement);
    file.writeAsStringSync(content);
    print('Math updated successfully.');
  } else {
    print('Target string not found.');
  }
}
