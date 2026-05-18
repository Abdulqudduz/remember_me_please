import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/services/data_transfer_service.dart';
import '../../../core/widgets/primary_button.dart';

class ExportDataPage extends StatefulWidget {
  const ExportDataPage({super.key});

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  bool _isExporting = false;
  String? _statusMessage;

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
      _statusMessage = 'Preparing your data...';
    });

    try {
      final file = await DataTransferService.exportAllData();

      if (file != null && mounted) {
        setState(() {
          _statusMessage = 'Export package created.';
        });

        // Use share_plus to let the user save or send the file
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'RememberMe App Data Backup',
            text:
                'Use this file to restore your RememberMe data on another device.',
          ),
        );

        setState(() {
          _statusMessage = 'Export successful.';
        });
      } else {
        setState(() {
          _statusMessage = 'Export failed or No data to export.';
        });

        // Demo fallback: If no file (mock), show a message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Export failed. In this demo, the file creation is mocked.',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
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
          'Export Data',
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
            const Icon(
              Icons.unarchive_outlined,
              size: 100,
              color: AppColors.blueAccent,
            ),
            const SizedBox(height: 32),
            const Text(
              'Move to a New Device',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Exporting will create a single package containing all your locally saved information, including people, reminders, and conversation history.\n\nYou can send this file to your new device via Bluetooth, Email, or Messaging apps.',
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
                          _statusMessage!.contains('Error'))
                      ? AppColors.redAccent.withValues(alpha: 0.1)
                      : AppColors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        (_statusMessage!.contains('failed') ||
                            _statusMessage!.contains('Error'))
                        ? AppColors.redAccent
                        : AppColors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            PrimaryButton(
              label: _isExporting ? 'Exporting...' : 'Generate Export File',
              onPressed: _isExporting ? () {} : _handleExport,
              isFullWidth: true,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
