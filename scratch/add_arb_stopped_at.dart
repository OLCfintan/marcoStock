import 'dart:io';

void main() {
  final enFile = File('lib/src/localization/arb/app_en.arb');
  final frFile = File('lib/src/localization/arb/app_fr.arb');
  final arFile = File('lib/src/localization/arb/app_ar.arb');
  final esFile = File('lib/src/localization/arb/app_es.arb');
  
  void addKey(File file, String key, String value) {
    var content = file.readAsStringSync();
    if (content.contains('"$key"')) return;
    final insertIdx = content.lastIndexOf('}');
    content = content.replaceRange(insertIdx, insertIdx, '  ,"$key": "$value"\n');
    file.writeAsStringSync(content);
  }

  addKey(enFile, 'invoiceStoppedAt', 'The present invoice is stopped at the sum of :');
  addKey(frFile, 'invoiceStoppedAt', 'Arrêté la présente facture à la somme de :');
  addKey(arFile, 'invoiceStoppedAt', 'حصرت هذه الفاتورة في مبلغ :');
  addKey(esFile, 'invoiceStoppedAt', 'La presente factura se cierra por la suma de :');
}
