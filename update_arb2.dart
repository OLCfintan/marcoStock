import 'dart:convert';
import 'dart:io';

void main() {
  final files = {
    'en': 'lib/src/localization/arb/app_en.arb',
    'fr': 'lib/src/localization/arb/app_fr.arb',
    'ar': 'lib/src/localization/arb/app_ar.arb',
    'es': 'lib/src/localization/arb/app_es.arb',
  };

  final newKeys = {
    'en': { 'productLabel': 'Product' },
    'fr': { 'productLabel': 'Produit' },
    'ar': { 'productLabel': 'المنتج' },
    'es': { 'productLabel': 'Producto' }
  };

  for (final entry in files.entries) {
    final lang = entry.key;
    final path = entry.value;
    final file = File(path);
    if (file.existsSync()) {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      json.addAll(newKeys[lang]!);
      
      const encoder = JsonEncoder.withIndent('  ');
      file.writeAsStringSync(encoder.convert(json) + '\n');
    }
  }
}
