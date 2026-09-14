import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(databaseProvider));
});

class SyncService {
  final AppDatabase _db;
  Timer? _timer;
  bool _isSyncing = false;

  SyncService(this._db);

  void startBackgroundSync() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      processOutbox();
    });
  }

  void stopBackgroundSync() {
    _timer?.cancel();
  }

  Future<void> processOutbox() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await (_db.select(_db.syncOutbox)..where((t) => t.isSynced.equals(false))).get();
      if (pending.isEmpty) return;

      // Mock network call
      await Future.delayed(const Duration(seconds: 1));

      // Mark as synced locally
      for (final record in pending) {
        await _db.update(_db.syncOutbox).replace(
          record.copyWith(isSynced: true, syncedAt: drift.Value(DateTime.now()))
        );
      }
      
       
    } finally {
      _isSyncing = false;
    }
  }

  Future<String?> backupDatabase() async {
    final appDir = await getApplicationDocumentsDirectory();
    File dbFile = File(p.join(appDir.path, 'marco_stock.sqlite'));

    if (!await dbFile.exists()) {
      dbFile = File(p.join(appDir.path, 'markogroup_erp.sqlite'));
    }

    if (!await dbFile.exists()) {
      throw Exception('Database file not found: ${dbFile.path}');
    }

    final outputFile = await FilePicker.saveFile(
      dialogTitle: 'Save Database Backup',
      fileName: 'marco_stock_backup.sqlite',
    );

    if (outputFile != null) {
      await dbFile.copy(outputFile);
      return outputFile;
    }

    return null;
  }
}
