import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';
import '../documents/pdf_generator.dart';
import '../../presentation/widgets/print_dialog.dart';

final backupServiceProvider = Provider((ref) => BackupService(ref));

class BackupService {
  final Ref ref;
  BackupService(this.ref);

  Future<AppDatabase> get _db async => ref.read(databaseProvider);

  String _cleanFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  Future<void> exportData() async {
    final destDirStr = await FilePicker.getDirectoryPath(dialogTitle: 'Select destination for Marko-Save');
    if (destDirStr == null) return;

    final destDir = Directory(p.join(destDirStr, 'Marko-Save'));
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    final db = await _db;

    // 1. Force a WAL checkpoint to ensure all data is written to the main .sqlite file before copying
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');

    // Backup raw database
    final appDocs = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(appDocs.path, 'markogroup_erp.sqlite'));
    final systemBackupFile = File(p.join(destDir.path, 'system_backup.sqlite'));
    if (await dbFile.exists()) {
      await dbFile.copy(systemBackupFile.path);
    }
    
    // Open backup db to rewrite image paths
    final backupDb = sqlite.sqlite3.open(systemBackupFile.path);

    // 2. Export Products
    final productsDir = Directory(p.join(destDir.path, 'Products'));
    final prodImagesDir = Directory(p.join(productsDir.path, 'images'));
    await prodImagesDir.create(recursive: true);

    final productsListFile = File(p.join(productsDir.path, 'products_list.txt'));
    final products = await db.select(db.products).get();
    
    final prodStringBuffer = StringBuffer();
    prodStringBuffer.writeln("Products List:\n");

    for (var prod in products) {
      prodStringBuffer.writeln("Name: ${prod.name} | Family: ${prod.category} | Size: ${prod.unitSize}${prod.unit} | Price: ${prod.sellingPrice} | Buy: ${prod.purchasePrice}");
      
      if (prod.imagePath != null && prod.imagePath!.isNotEmpty) {
        final imgFile = File(prod.imagePath!);
        if (await imgFile.exists()) {
          final ext = p.extension(prod.imagePath!);
          final cleanName = _cleanFileName('${prod.name}_${prod.unitSize}${prod.unit}');
          final newImageName = '$cleanName$ext';
          final destImg = p.join(prodImagesDir.path, newImageName);
          await imgFile.copy(destImg);
          
          backupDb.execute("UPDATE products SET image_path = ? WHERE id = ?", [newImageName, prod.id]);
        }
      }
    }
    await productsListFile.writeAsString(prodStringBuffer.toString());

    // Helper for humans
    Future<void> exportHuman(bool isClient) async {
      final baseDir = Directory(p.join(destDir.path, isClient ? 'Clients' : 'Suppliers'));
      await baseDir.create(recursive: true);

      final humans = isClient ? await db.select(db.clients).get() : await db.select(db.suppliers).get();
      
      for (var h in humans) {
        final humanId = isClient ? (h as ClientEntity).id : (h as SupplierEntity).id;
        final humanName = isClient ? (h as ClientEntity).name : (h as SupplierEntity).name;
        final humanBalance = isClient ? (h as ClientEntity).balance : (h as SupplierEntity).balance;
        final humanPhone = isClient ? (h as ClientEntity).phone : (h as SupplierEntity).phone;
        final humanImg = isClient ? (h as ClientEntity).imagePath : (h as SupplierEntity).imagePath;

        final hDir = Directory(p.join(baseDir.path, _cleanFileName(humanName)));
        await hDir.create(recursive: true);

        // Save Info
        final infoFile = File(p.join(hDir.path, 'infos.txt'));
        await infoFile.writeAsString("Name: $humanName\nPhone: ${humanPhone ?? 'N/A'}\nBalance: $humanBalance Dhs\n");

        // Copy Image
        if (humanImg != null && humanImg.isNotEmpty) {
          final imgFile = File(humanImg);
          if (await imgFile.exists()) {
            final ext = p.extension(humanImg);
            final newImageName = '${_cleanFileName(humanName)}_profile$ext';
            await imgFile.copy(p.join(hDir.path, newImageName));
            
            final table = isClient ? 'clients' : 'suppliers';
            backupDb.execute("UPDATE $table SET image_path = ? WHERE id = ?", [newImageName, humanId]);
          }
        }

        // Bon & Facture Folders
        final bonDir = Directory(p.join(hDir.path, 'Bon'));
        final factDir = Directory(p.join(hDir.path, 'Facture'));
        await bonDir.create(recursive: true);
        await factDir.create(recursive: true);

        final paymentStateBuffer = StringBuffer();
        paymentStateBuffer.writeln("=== DOCUMENTS ===");

        if (isClient) {
          final invoices = await (db.select(db.invoices)..where((t) => t.clientId.equals(humanId))).get();
          for (var inv in invoices) {
            paymentStateBuffer.writeln("${inv.documentType} #${inv.invoiceNumber} | Total: ${inv.total} | Paid: ${inv.paidAmount} | Status: ${inv.status} | Date: ${inv.date}");
            
            try {
              final pdfBytes = await ref.read(pdfGeneratorProvider).generateInvoicePdf(inv.id, PrintOptions(layout: PrintLayout.a4, languageCode: 'fr'));
              final folder = inv.documentType == 'BON' ? bonDir : factDir;
              final pdfFile = File(p.join(folder.path, '${_cleanFileName(inv.invoiceNumber)}.pdf'));
              await pdfFile.writeAsBytes(pdfBytes);
            } catch (e) {
              print("Failed to generate PDF for ${inv.invoiceNumber}: $e");
            }
          }
        } else {
          final purchases = await (db.select(db.purchases)..where((t) => t.supplierId.equals(humanId))).get();
          for (var pur in purchases) {
            paymentStateBuffer.writeln("${pur.documentType} #${pur.purchaseNumber} | Total: ${pur.total} | Paid: ${pur.paidAmount} | Status: ${pur.status} | Date: ${pur.date}");
            
            try {
              final pdfBytes = await ref.read(pdfGeneratorProvider).generatePurchasePdf(pur.id, PrintOptions(layout: PrintLayout.a4, languageCode: 'fr'));
              final folder = pur.documentType == 'BON' ? bonDir : factDir;
              final pdfFile = File(p.join(folder.path, '${_cleanFileName(pur.purchaseNumber)}.pdf'));
              await pdfFile.writeAsBytes(pdfBytes);
            } catch (e) {
              print("Failed to generate PDF for ${pur.purchaseNumber}: $e");
            }
          }
        }

        paymentStateBuffer.writeln("\n=== PAYMENTS ===");
        final payments = await (db.select(db.payments)..where((t) => isClient ? t.clientId.equals(humanId) : t.supplierId.equals(humanId))).get();
        for (var pay in payments) {
          paymentStateBuffer.writeln("Date: ${pay.date} | Amount: ${pay.amount} | Method: ${pay.method} | Status: ${pay.status}");
        }

        final paymentStateFile = File(p.join(hDir.path, 'payment_state.txt'));
        await paymentStateFile.writeAsString(paymentStateBuffer.toString());
      }
    }

    await exportHuman(true);  // Clients
    await exportHuman(false); // Suppliers
    
    backupDb.dispose();
  }

  Future<void> importData() async {
    final srcDirStr = await FilePicker.getDirectoryPath(dialogTitle: 'Select Marko-Save folder to import');
    if (srcDirStr == null) return;

    final srcDir = Directory(srcDirStr);
    final systemBackup = File(p.join(srcDir.path, 'system_backup.sqlite'));

    if (!await systemBackup.exists()) {
      throw Exception('Valid Marko-Save system_backup.sqlite not found in the selected folder!');
    }

    final appDocs = await getApplicationDocumentsDirectory();
    final markoAssetsDir = Directory(p.join(appDocs.path, 'marko_assets'));
    if (!await markoAssetsDir.exists()) {
      await markoAssetsDir.create(recursive: true);
    }

    // 1. Copy backup to a temporary file so we can safely mutate image paths BEFORE overwriting active DB
    final tempDbFile = File(p.join(appDocs.path, 'temp_restore.sqlite'));
    try {
      final bytes = await systemBackup.readAsBytes();
      await tempDbFile.writeAsBytes(bytes, flush: true);
    } catch (e) {
      if (e.toString().contains('Permission denied')) {
        throw Exception('Permission Denied by Android Security. Please MOVE the Marko-Save folder out of WhatsApp into your main Downloads or Documents folder, and try importing it from there.');
      }
      throw Exception('Failed to read backup: $e');
    }

    // 2. Open temporary DB with raw sqlite3
    final tempDb = sqlite.sqlite3.open(tempDbFile.path);

    // 3. Process Products Images Dynamic Mapping
    final products = tempDb.select("SELECT id, image_path FROM products WHERE image_path IS NOT NULL AND image_path != '';");
    for (var row in products) {
      final id = row['id'] as String;
      final oldPathOrName = row['image_path'] as String;
      final basename = p.basename(oldPathOrName);
      
      File expectedExportPath = File(p.join(srcDir.path, 'Products', 'images', basename));
      if (!await expectedExportPath.exists()) {
        expectedExportPath = File(p.join(srcDir.path, 'Products', 'images', '${id}_$basename'));
      }
      
      final newAssetPath = File(p.join(markoAssetsDir.path, 'prod_${id}_$basename'));
      
      if (await expectedExportPath.exists()) {
        await expectedExportPath.copy(newAssetPath.path);
        tempDb.execute("UPDATE products SET image_path = ? WHERE id = ?", [newAssetPath.path, id]);
      }
    }

    // 4. Process Clients Images Dynamic Mapping
    final clients = tempDb.select("SELECT id, name, image_path FROM clients WHERE image_path IS NOT NULL AND image_path != '';");
    for (var row in clients) {
      final id = row['id'] as String;
      final name = row['name'] as String;
      final oldPathOrName = row['image_path'] as String;
      final basename = p.basename(oldPathOrName);
      
      final cleanName = _cleanFileName(name);
      File expectedExportPath = File(p.join(srcDir.path, 'Clients', cleanName, basename));
      if (!await expectedExportPath.exists()) {
        expectedExportPath = File(p.join(srcDir.path, 'Clients', cleanName, 'profileImage_$basename'));
      }
      
      final newAssetPath = File(p.join(markoAssetsDir.path, 'client_${id}_$basename'));
      
      if (await expectedExportPath.exists()) {
        await expectedExportPath.copy(newAssetPath.path);
        tempDb.execute("UPDATE clients SET image_path = ? WHERE id = ?", [newAssetPath.path, id]);
      }
    }

    // 5. Process Suppliers Images Dynamic Mapping
    final suppliers = tempDb.select("SELECT id, name, image_path FROM suppliers WHERE image_path IS NOT NULL AND image_path != '';");
    for (var row in suppliers) {
      final id = row['id'] as String;
      final name = row['name'] as String;
      final oldPathOrName = row['image_path'] as String;
      final basename = p.basename(oldPathOrName);
      
      final cleanName = _cleanFileName(name);
      File expectedExportPath = File(p.join(srcDir.path, 'Suppliers', cleanName, basename));
      if (!await expectedExportPath.exists()) {
        expectedExportPath = File(p.join(srcDir.path, 'Suppliers', cleanName, 'profileImage_$basename'));
      }
      
      final newAssetPath = File(p.join(markoAssetsDir.path, 'supplier_${id}_$basename'));
      
      if (await expectedExportPath.exists()) {
        await expectedExportPath.copy(newAssetPath.path);
        tempDb.execute("UPDATE suppliers SET image_path = ? WHERE id = ?", [newAssetPath.path, id]);
      }
    }

    tempDb.dispose();

    // 6. Execute Algebric Replacement of active DB
    final dbFile = File(p.join(appDocs.path, 'markogroup_erp.sqlite'));
    await tempDbFile.copy(dbFile.path);
    
    // Crucial: Delete WAL and SHM files so they don't overwrite our newly imported DB
    final walFile = File('${dbFile.path}-wal');
    final shmFile = File('${dbFile.path}-shm');
    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();

    await tempDbFile.delete(); // Cleanup
  }
}
