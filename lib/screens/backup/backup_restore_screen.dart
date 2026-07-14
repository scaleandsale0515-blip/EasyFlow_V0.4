import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../models/app_settings.dart';
import '../../services/hive_service.dart';
import '../../services/backup_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

enum _RestoreChoice { backupFirst, continueAnyway, cancel }

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _busy = false;

  Future<void> _createBackup({bool silent = false}) async {
    if (!silent) setState(() => _busy = true);
    try {
      final file = await BackupService.createBackup();
      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'EasyFlow Backup');
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      rethrow;
    } finally {
      if (!silent && mounted) setState(() => _busy = false);
    }
  }

  /// Warns clearly that Restore replaces everything currently on the phone,
  /// and offers to safely back up what's here right now before proceeding -
  /// so nothing is ever lost without a copy of it existing somewhere first.
  Future<void> _restoreBackup() async {
    final choice = await showDialog<_RestoreChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'Restoring will replace ALL current data with this backup. Anything added after this backup was made will be lost.\n\nTake a backup of your current data first?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, _RestoreChoice.cancel), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, _RestoreChoice.continueAnyway), child: const Text('Continue Without Backup')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, _RestoreChoice.backupFirst), child: const Text('Backup Current Data First')),
        ],
      ),
    );
    if (choice == null || choice == _RestoreChoice.cancel) return;

    if (choice == _RestoreChoice.backupFirst) {
      setState(() => _busy = true);
      try {
        await _createBackup(silent: true);
      } catch (_) {
        // _createBackup already showed the error; stop here rather than
        // proceeding to restore on top of a failed safety backup.
        if (mounted) setState(() => _busy = false);
        return;
      }
    }

    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (result == null || result.files.single.path == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }

    setState(() => _busy = true);
    try {
      await BackupService.restoreBackup(File(result.files.single.path!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore complete. Please restart the app to see the restored data (your login will NOT be asked again).')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box<AppSettings>(HiveBoxes.appSettings);
    final lastBackup = settingsBox.isNotEmpty ? settingsBox.getAt(0)!.lastBackupDate : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.accentCyan),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lastBackup == null
                              ? 'No backup taken yet. It\'s recommended to back up regularly.'
                              : 'Last backup: ${Fmt.date(lastBackup)}',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'Creates a complete backup of all your business data - Production, Transport, Workers, Transporters, Item Catalog, Company Profile, Opening Stock/Threshold, and photos (compressed to keep file size small). Your login and app settings on this device are never included.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(onPressed: _createBackup, icon: const Icon(Icons.backup_outlined), label: const Text('Create & Share Backup')),
                const SizedBox(height: 32),
                const Text('Restore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'Restores business data from a previously created backup .zip file. This will overwrite all current business data. Your login/activation on this device is never affected by restore.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: _restoreBackup, icon: const Icon(Icons.restore_outlined), label: const Text('Restore from Backup File')),
              ],
            ),
    );
  }
}
