import 'dart:io';
import 'dart:convert';

void updateArb(String path, String bonLabel, String bonToLabel) {
  final file = File(path);
  final content = file.readAsStringSync();
  final Map<String, dynamic> json = jsonDecode(content);
  
  json['bon'] = bonLabel;
  json['pdfBonTo'] = bonToLabel;
  
  // Format beautifully
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(json));
}

void main() {
  updateArb('lib/src/localization/arb/app_fr.arb', 'BON', 'BON à :');
  updateArb('lib/src/localization/arb/app_en.arb', 'BON', 'BON To:');
  updateArb('lib/src/localization/arb/app_es.arb', 'BON', 'BON a:');
  updateArb('lib/src/localization/arb/app_ar.arb', 'بون', 'بون إلى:');
  print('ARBs updated');
}
