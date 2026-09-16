import 'dart:io';
import '../system/unit_conversion_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';
import 'package:drift/drift.dart' as drift;
import 'package:decimal/decimal.dart';

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(ref.watch(databaseProvider));
});

class ImportService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ImportService(this._db);

  Future<String> importData() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv', 'pdf'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return 'No files selected.';

      int clientsAdded = 0;
      int suppliersAdded = 0;
      int productsAdded = 0;

      for (final file in result.files) {
        if (file.path == null) continue;
        
        String content = '';
        if (file.path!.toLowerCase().endsWith('.pdf')) {
          try {
            final bytes = await File(file.path!).readAsBytes();
            final PdfDocument document = PdfDocument(inputBytes: bytes);
            content = PdfTextExtractor(document).extractText();
            document.dispose();
          } catch (e) {
            continue;
          }
        } else {
          content = await File(file.path!).readAsString();
        }
        final blocks = content.split('---');

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
          if (type == 'CLIENT') {
            await _db.into(_db.clients).insert(ClientsCompanion(
              id: drift.Value(_uuid.v4()),
              name: drift.Value(map['NAME'] ?? 'Unknown Client'),
              type: const drift.Value('NORMAL'),
              phone: drift.Value(map['PHONE']),
              address: drift.Value(map['ADDRESS']),
              balance: drift.Value(Decimal.zero),
            ));
            clientsAdded++;
          } else if (type == 'SUPPLIER') {
            await _db.into(_db.suppliers).insert(SuppliersCompanion(
              id: drift.Value(_uuid.v4()),
              name: drift.Value(map['NAME'] ?? 'Unknown Supplier'),
              phone: drift.Value(map['PHONE']),
              email: drift.Value(map['EMAIL']),
              balance: drift.Value(Decimal.zero),
            ));
            suppliersAdded++;
          } else if (type == 'PRODUCT') {
            final refVal = map['REFERENCE'] ?? _uuid.v4().substring(0, 8).toUpperCase();
            final existingProduct = await (_db.select(_db.products)..where((t) => t.reference.equals(refVal))).getSingleOrNull();
            
            final companion = ProductsCompanion(
              name: drift.Value(map['NAME'] ?? (existingProduct?.name ?? 'Unknown Product')),
              nameAr: map['NAMEAR'] != null ? drift.Value(map['NAMEAR']) : const drift.Value.absent(),
              nameFr: map['NAMEFR'] != null ? drift.Value(map['NAMEFR']) : const drift.Value.absent(),
              nameEs: map['NAMEES'] != null ? drift.Value(map['NAMEES']) : const drift.Value.absent(),
              reference: drift.Value(refVal),
              unit: drift.Value(() {
                final u = map['UNIT'] ?? existingProduct?.unit ?? 'Unit';
                try {
                  return UnitConversionService.allUnits.firstWhere((e) => e.toLowerCase() == u.toLowerCase());
                } catch (_) {
                  return 'Unit';
                }
              }()),
              unitSize: drift.Value(Decimal.tryParse(map['UNITSIZE'] ?? '') ?? existingProduct?.unitSize ?? Decimal.one),
              unitsPerBox: drift.Value(int.tryParse(map['UNITSPERBOX'] ?? map['BOXUNITS'] ?? '') ?? existingProduct?.unitsPerBox ?? 1),
              purchasePrice: drift.Value(Decimal.tryParse(map['PURCHASEPRICE'] ?? '') ?? existingProduct?.purchasePrice ?? Decimal.zero),
              sellingPrice: drift.Value(Decimal.tryParse(map['PRICE'] ?? map['SELLINGPRICE'] ?? '') ?? existingProduct?.sellingPrice ?? Decimal.zero),
              minimumStock: drift.Value(Decimal.tryParse(map['MINSTOCK'] ?? '') ?? existingProduct?.minimumStock ?? Decimal.zero),
              baseMinimumStock: drift.Value(Decimal.tryParse(map['BASEMINSTOCK'] ?? '') ?? existingProduct?.baseMinimumStock ?? Decimal.zero),
              magazinMinimumStock: drift.Value(Decimal.tryParse(map['MAGAZINMINSTOCK'] ?? '') ?? existingProduct?.magazinMinimumStock ?? Decimal.zero),
              tier2Price: drift.Value(Decimal.tryParse(map['TIER2PRICE'] ?? '0') ?? existingProduct?.tier2Price ?? Decimal.zero),
              tier3Price: drift.Value(Decimal.tryParse(map['TIER3PRICE'] ?? '0') ?? existingProduct?.tier3Price ?? Decimal.zero),
              packagingType: drift.Value(() {
                 final p = map['PACKAGING'] ?? existingProduct?.packagingType ?? 'Unit';
                 final opts = ['Unit', 'Box', 'Ticket', 'Bottle'];
                 return opts.contains(p) ? p : (opts.map((o) => o.toLowerCase()).contains(p.toLowerCase()) ? 
                        opts.firstWhere((o) => o.toLowerCase() == p.toLowerCase()) : 'Unit');
              }()),
              isActive: const drift.Value(true),
            );

            if (existingProduct != null) {
              await (_db.update(_db.products)..where((t) => t.id.equals(existingProduct.id))).write(companion);
            } else {
              await _db.into(_db.products).insert(companion.copyWith(id: drift.Value(_uuid.v4())));
            }
            productsAdded++;
          }
        }
      }

      return 'Import Success! Added $clientsAdded Clients, $suppliersAdded Suppliers, and $productsAdded Products.';
    } catch (e) {
      return 'Error during import: $e\nPlease ensure strict format (e.g., TYPE: PRODUCT\\nNAME: ...\\n---)';
    }
  }
}
