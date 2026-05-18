import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/services/data_transfer_service.dart';

class ImportDataPage extends StatefulWidget {
  const ImportDataPage({super.key});

  @override
  State<ImportDataPage> createState() => _ImportDataPageState();
}

class _ImportDataPageState extends State<ImportDataPage> {
  bool _isImporting = false;
  String? _statusMessage;

  Future<void> _handleImport() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Basic extension check
        if (!file.path.endsWith('.rmb')) {
          setState(() {
            _statusMessage = 'Invalid file format. Please select a .rmb file.';
          });
          return;
        }

        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.scaffoldBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: const Text(
              'Confirm Import',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            content: const Text(
              'Importing data will overwrite your current information. This cannot be undone.\n\nAre you sure?',
              style: TextStyle(fontSize: 16, color: AppColors.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Import',
                  style: TextStyle(
                    color: AppColors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          setState(() {
            _isImporting = true;
            _statusMessage = 'Restoring data...';
          });

          final success = await DataTransferService.importData(file);

          if (success && mounted) {
            setState(() {
              _statusMessage =
                  'Import successful! Please restart the app for changes to take effect.';
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data restored successfully.')),
            );
          } else {
            setState(() {
              _statusMessage = 'Import failed. The file might be corrupted.';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        surfaceTintColor: AppColors.transparent,
        backgroundColor: AppColors.transparent,
        elevation: 0,
        title: const Text(
          'Import Data',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.archive_outlined, size: 100, color: AppColors.green),
            const SizedBox(height: 32),
            const Text(
              'Restore from Backup',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Select a previously exported data package (.rmb) to restore your information on this device.\n\nWarning: This will replace all current data with the information from the backup file.',
              style: TextStyle(
                fontSize: 18,
                height: 1.6,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      (_statusMessage!.contains('failed') ||
                          _statusMessage!.contains('Error') ||
                          _statusMessage!.contains('Invalid'))
                      ? AppColors.redAccent.withValues(alpha: 0.1)
                      : AppColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        (_statusMessage!.contains('failed') ||
                            _statusMessage!.contains('Error') ||
                            _statusMessage!.contains('Invalid'))
                        ? AppColors.redAccent
                        : AppColors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              height: 72,
              child: ElevatedButton(
                onPressed: _isImporting ? null : _handleImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isImporting ? 'Importing...' : 'Select Backup File',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
