import 'package:flutter_test/flutter_test.dart';
import 'package:marko_group/src/infrastructure/database/app_database.dart';
import 'package:flutter/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Check if DB has products', () async {
    final db = AppDatabase();
    final p = await db.select(db.products).get();
    print('Products count: ${p.length}');
    if (p.isNotEmpty) {
      print('First product: ${p.first.name} - active: ${p.first.isActive}');
      print('Active products count: ${p.where((e) => e.isActive).length}');
    }
  });
}
