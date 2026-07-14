import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import 'hive_service.dart';

class BackupService {
  /// Hive box filename(s) that must NEVER be included in a backup, and must
  /// NEVER be overwritten during a restore - these hold device-level state
  /// (admin activation status, admin ID/password hashes, theme choice,
  /// dashboard chart on/off toggles) that belongs to THIS device/sale, not
  /// to the portable business data being backed up or restored.
  static const _deviceOnlyFiles = {'app_settings.hive', 'app_settings.lock'};

  /// Creates a single .zip file containing every business-data Hive box
  /// file and every image folder (worker photos, company logo - already
  /// compressed on save, so backup size stays minimal). Device-level
  /// settings (activation/login/theme/chart toggles) are deliberately
  /// excluded. Returns the zip file.
  static Future<File> createBackup() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final archive = Archive();

    // Hive stores each box as <boxName>.hive (+ .lock) directly in the
    // documents dir when initFlutter() is used without a subdirectory.
    final hiveFiles = docsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.hive'))
        .where((f) => !_deviceOnlyFiles.contains(f.path.split(Platform.pathSeparator).last));
    for (final f in hiveFiles) {
      final bytes = await f.readAsBytes();
      final name = f.path.split(Platform.pathSeparator).last;
      archive.addFile(ArchiveFile('hive/$name', bytes.length, bytes));
    }

    // Image folders
    for (final folder in ['worker_photos', 'company_logo']) {
      final dir = Directory('${docsDir.path}/$folder');
      if (await dir.exists()) {
        final files = dir.listSync().whereType<File>();
        for (final f in files) {
          final bytes = await f.readAsBytes();
          final name = f.path.split(Platform.pathSeparator).last;
          archive.addFile(ArchiveFile('$folder/$name', bytes.length, bytes));
        }
      }
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('Sorry, Failed to create backup: zip encoding returned null');
    }
    final backupDir = Directory('${docsDir.path}/backups');
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFile = File('${backupDir.path}/EasyFlow_Backup_$timestamp.zip');
    await zipFile.writeAsBytes(zipData);

    // Record backup date for the 30-day reminder banner. This itself is a
    // device-level field (when did THIS device last back up), so it stays
    // in AppSettings and is correctly excluded from the backup file above.
    final settingsBox = Hive.box<AppSettings>(HiveBoxes.appSettings);
    final settings = settingsBox.getAt(0);
    if (settings != null) {
      settings.lastBackupDate = DateTime.now();
      await settings.save();
    }

    return zipFile;
  }

  /// Restores from a previously created backup zip. Closes all Hive boxes,
  /// overwrites the business-data box files + image folders, then reopens
  /// everything. Device-level settings (app_settings.hive) are always
  /// skipped during restore - even if an OLDER backup (made before this
  /// safeguard existed) happens to contain that file, it's deliberately
  /// ignored so a restore can never reset this device's activation/login/
  /// theme/chart state.
  static Future<void> restoreBackup(File zipFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    await HiveService.closeAll();

    for (final file in archive) {
      if (!file.isFile) continue;
      final parts = file.name.split('/');
      if (parts.length < 2) continue;
      final folder = parts[0];
      final fileName = parts.sublist(1).join('/');

      if (folder == 'hive' && _deviceOnlyFiles.contains(fileName)) {
        continue; // never let restore touch device-level settings
      }

      String targetPath;
      if (folder == 'hive') {
        targetPath = '${docsDir.path}/$fileName';
      } else {
        final targetDir = Directory('${docsDir.path}/$folder');
        if (!await targetDir.exists()) await targetDir.create(recursive: true);
        targetPath = '${targetDir.path}/$fileName';
      }
      final outFile = File(targetPath);
      await outFile.writeAsBytes(file.content as List<int>);
    }

    await HiveService.init();
  }
}
