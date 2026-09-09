import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupService {
  Future<String> createBackup() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, 'markogroup.sqlite');
    
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('Database file not found');
    }
    
    final backupDir = await getDownloadsDirectory() ?? appDir;
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final zipPath = p.join(backupDir.path, 'markogroup_backup_$timestamp.zip');
    
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    encoder.addFile(dbFile);
    encoder.close();
    
    return zipPath;
  }
}
