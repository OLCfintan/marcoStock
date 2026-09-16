import 'package:marko_group/src/application/import/import_service.dart';
import 'package:marko_group/src/infrastructure/database/app_database.dart';
import 'dart:io';

void main() async {
  final db = AppDatabase();
  final service = ImportService(db);
  // We can't use FilePicker in a script. So we'll just read the file manually and apply the logic.
  
  final file = File('import_products.txt');
  final content = await file.readAsString();
  final blocks = content.split('---');

  int productsAdded = 0;
  for (final block in blocks) {
    final lines = block.trim().split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) continue;

    final map = <String, String>{};
    for (final line in lines) {
      final splitIndex = line.indexOf(':');
      if (splitIndex != -1) {
        final rawKey = line.substring(0, splitIndex).trim().toUpperCase();
        final key = rawKey.replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
        final value = line.substring(splitIndex + 1).trim();
        map[key] = value;
      }
    }

    final type = map['TYPE']?.toUpperCase();
    if (type == 'PRODUCT') {
      productsAdded++;
    }
  }
  print('Parsed $productsAdded products.');
}
