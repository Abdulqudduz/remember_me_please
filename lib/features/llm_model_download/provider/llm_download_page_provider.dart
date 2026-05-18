import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remember_me_please/core/models/download_models.dart';
import 'package:remember_me_please/core/services/huggingface_auth_service.dart';
import 'package:remember_me_please/features/llm_model_download/page/constants/constants.dart';
import '../../../core/services/huggingface_download_service.dart';
import '../../../core/services/zip_extraction_service.dart';

// Track the state of each specific model
enum ModelState { notStarted, downloading, extracting, success, failed }

class LlmDownloadProvider extends ChangeNotifier {
  final HuggingFaceDownloadService _downloadService =
      HuggingFaceDownloadService();
  final HuggingFaceAuthService _authService = HuggingFaceAuthService();

  // --- Gemma State ---
  String? _gemmaTaskId;
  DownloadProgress? _gemmaProgress;
  ModelState _gemmaState = ModelState.notStarted;
  String _gemmaStatusText = "Ready";

  // --- Additional Models State ---
  String? _additionalTaskId;
  DownloadProgress? _additionalProgress;
  ModelState _additionalState = ModelState.notStarted;
  String _additionalStatusText = "Waiting for Gemma...";
  bool _isCancelRequested = false;

  // Getters
  DownloadProgress? get gemmaProgress => _gemmaProgress;
  ModelState get gemmaState => _gemmaState;
  String get gemmaStatusText => _gemmaStatusText;

  DownloadProgress? get additionalProgress => _additionalProgress;
  ModelState get additionalState => _additionalState;
  String get additionalStatusText => _additionalStatusText;

  // General state
  bool get isAnyDownloading =>
      _gemmaState == ModelState.downloading ||
      _additionalState == ModelState.downloading ||
      _additionalState == ModelState.extracting;

  bool get isEverythingComplete =>
      _gemmaState == ModelState.success &&
      _additionalState == ModelState.success;

  Timer? _monitoringTimer;

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }

  // --- 1. Start the Gemma Download ---
  Future<void> startGemmaDownload() async {
    try {
      final authToken = await _authService.authenticateUser();
      if (authToken == null) {
        _gemmaStatusText = 'Auth failed or cancelled.';
        _gemmaState = ModelState.failed;
        notifyListeners();
        return;
      }

      _gemmaState = ModelState.downloading;
      _gemmaStatusText = 'Starting...';
      notifyListeners();

      _gemmaTaskId = await _downloadService.downloadModel(authToken);
      if (_gemmaTaskId != null) {
        _startMonitoring();
      } else {
        _gemmaState = ModelState.failed;
        notifyListeners();
      }
    } catch (e) {
      _gemmaStatusText = 'Error: $e';
      _gemmaState = ModelState.failed;
      notifyListeners();
    }
  }

  // --- 2. Start the Additional Models Download ---
  Future<void> _startAdditionalModelsDownload() async {
    _additionalState = ModelState.downloading;
    _additionalStatusText = 'Starting...';
    notifyListeners();

    try {
      _additionalTaskId = await _downloadService.downloadSupportingModels();
      if (_additionalTaskId != null) {
        // If the timer isn't running, start it
        if (!(_monitoringTimer?.isActive ?? false)) {
          _startMonitoring();
        }
      } else {
        _additionalState = ModelState.failed;
        _additionalStatusText = "Failed to start.";
        notifyListeners();
      }
    } catch (e) {
      _additionalState = ModelState.failed;
      _additionalStatusText = "Error: $e";
      notifyListeners();
    }
  }

  // --- Global Monitoring Timer ---
  void _startMonitoring() {
    _monitoringTimer?.cancel();

    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      final tasks = await _downloadService.getActiveDownloads();

      // Monitor Gemma if active
      if (_gemmaTaskId != null && _gemmaState == ModelState.downloading) {
        _checkGemmaTask(tasks);
      }

      // Monitor Additional Models if active
      if (_additionalTaskId != null &&
          _additionalState == ModelState.downloading) {
        _checkAdditionalTask(tasks);
      }

      // Stop timer if nothing is downloading
      if (_gemmaState != ModelState.downloading &&
          _additionalState != ModelState.downloading) {
        timer.cancel();
      }
    });
  }

  void _checkGemmaTask(List<DownloadTask> tasks) {
    final task = tasks.firstWhere(
      (t) => t.taskId == _gemmaTaskId,
      orElse: () => DownloadTask(
        taskId: '',
        status: DownloadTaskStatus.undefined,
        progress: 0,
        url: '',
        savedDir: '',
        timeCreated: 0,
        allowCellular: true,
        filename: '',
      ),
    );

    if (task.taskId.isEmpty) return;

    _gemmaProgress = DownloadProgress(
      totalBytes: 100,
      downloadedBytes: task.progress,
      downloadRate: 0,
      remainingTime: Duration.zero,
      status: task.status,
    );

    if (task.status == DownloadTaskStatus.complete) {
      _gemmaState = ModelState.success;
      _gemmaStatusText = 'Complete!';
      _gemmaTaskId = null;
      notifyListeners();

      // AUTO-START NEXT DOWNLOAD
      if (_additionalState == ModelState.notStarted) {
        _startAdditionalModelsDownload();
      }
    } else if (task.status == DownloadTaskStatus.failed) {
      _gemmaState = ModelState.failed;
      _gemmaStatusText = 'Failed.';
      _gemmaTaskId = null;
      notifyListeners();
    } else if (task.status == DownloadTaskStatus.running) {
      _gemmaStatusText = '${task.progress}%';
      notifyListeners();
    }
  }

  Future<void> _checkAdditionalTask(List<DownloadTask> tasks) async {
    final task = tasks.firstWhere(
      (t) => t.taskId == _additionalTaskId,
      orElse: () => DownloadTask(
        taskId: '',
        status: DownloadTaskStatus.undefined,
        progress: 0,
        url: '',
        savedDir: '',
        timeCreated: 0,
        allowCellular: true,
        filename: '',
      ),
    );

    if (task.taskId.isEmpty) return;

    _additionalProgress = DownloadProgress(
      totalBytes: 100,
      downloadedBytes: task.progress,
      downloadRate: 0,
      remainingTime: Duration.zero,
      status: task.status,
    );

    if (task.status == DownloadTaskStatus.complete) {
      _additionalTaskId = null;
      _additionalState = ModelState.extracting;
      _additionalStatusText = 'Extracting zip...';
      _additionalProgress = DownloadProgress(
        totalBytes: 100,
        downloadedBytes: 100,
        downloadRate: 0,
        remainingTime: Duration.zero,
        status: DownloadTaskStatus.running,
      ); // Keep bar full
      notifyListeners();

      try {
        final appDir = await getApplicationDocumentsDirectory();
        await ZipExtractionService.extractModelsZip(appDir.path, "models.zip");

        _additionalState = ModelState.success;
        _additionalStatusText = 'Ready!';
      } catch (e) {
        _additionalState = ModelState.failed;
        _additionalStatusText = 'Extraction failed.';
      }
      notifyListeners();
    } else if (task.status == DownloadTaskStatus.failed) {
      _additionalState = ModelState.failed;
      _additionalStatusText = 'Failed.';
      _additionalTaskId = null;
      notifyListeners();
    } else if (task.status == DownloadTaskStatus.running) {
      _additionalStatusText = '${task.progress}%';
      notifyListeners();
    }
  }

  // --- File Picker Logic ---
  Future<void> importModelFromDevice() async {
    try {
      _isCancelRequested = false;
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['litertlm'],
      );
      if (result == null || result.files.single.path == null) return;

      String pickedPath = result.files.single.path!;
      final String expectedName = result.files.single.name;

      if (!expectedName.toLowerCase().endsWith('.litertlm')) {
        _gemmaStatusText = 'Invalid format.';
        _gemmaState = ModelState.failed;
        notifyListeners();
        return;
      }

      File sourceFile = File(pickedPath);
      final totalBytes = await sourceFile.length();

      _gemmaState = ModelState.downloading; // Reuse downloading state for UI
      _gemmaStatusText = 'Importing...';
      notifyListeners();

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String destPath = '${appDir.path}/$expectedName';

      if (sourceFile.path != destPath) {
        final destFile = File(destPath);
        if (!await appDir.exists()) await appDir.create(recursive: true);
        if (await destFile.exists()) await destFile.delete();

        final readStream = sourceFile.openRead();
        final writeSink = destFile.openWrite();
        int copiedBytes = 0;

        try {
          await for (final chunk in readStream) {
            // Check if user pressed cancel during the copy
            if (_isCancelRequested) {
              break;
            }

            writeSink.add(chunk);
            copiedBytes += chunk.length;
            _gemmaProgress = DownloadProgress(
              totalBytes: totalBytes,
              downloadedBytes: copiedBytes,
              downloadRate: 0,
              remainingTime: Duration.zero,
              status: DownloadTaskStatus.running,
            );
            notifyListeners();
          }
        } finally {
          await writeSink.flush();
          await writeSink.close();
        }

        // If cancelled, delete the partially written file and exit
        if (_isCancelRequested) {
          if (await destFile.exists()) {
            await destFile.delete();
          }
          return;
        }
      }
      // IMPORT SUCCESS!
      _gemmaState = ModelState.success;
      _gemmaStatusText = 'Imported!';
      _gemmaProgress = DownloadProgress(
        totalBytes: 100,
        downloadedBytes: 100,
        downloadRate: 0,
        remainingTime: Duration.zero,
        status: DownloadTaskStatus.complete,
      );
      notifyListeners();

      // AUTO-START NEXT DOWNLOAD
      if (_additionalState == ModelState.notStarted) {
        _startAdditionalModelsDownload();
      }
    } catch (e) {
      _gemmaStatusText = 'Failed to import.';
      _gemmaState = ModelState.failed;
      notifyListeners();
    }
  }

  Future<void> cancelCurrentDownload() async {
    _isCancelRequested = true;
    if (_gemmaTaskId != null) {
      await _downloadService.cancelDownload(_gemmaTaskId!);
    }
    if (_additionalTaskId != null) {
      await _downloadService.cancelDownload(_additionalTaskId!);
    }

    _monitoringTimer?.cancel();
    _gemmaTaskId = null;
    _additionalTaskId = null;

    _gemmaState = ModelState.failed;
    _additionalState = ModelState.failed;
    _gemmaStatusText = 'Cancelled';
    _additionalStatusText = 'Cancelled';
    notifyListeners();

    // Hard cleanup of all target files to ensure no corrupt/partial data remains
    try {
      final appDir = await getApplicationDocumentsDirectory();

      // Attempt to delete Gemma model
      final gemmaFile = File(
        '${appDir.path}/$modelName',
      ); // Ensure 'modelName' is imported from your constants
      if (await gemmaFile.exists()) await gemmaFile.delete();

      // Attempt to delete the models.zip
      final zipFile = File('${appDir.path}/models.zip');
      if (await zipFile.exists()) await zipFile.delete();

      // Attempt to delete the extracted models folder if it was mid-extraction
      final modelsDir = Directory('${appDir.path}/models');
      if (await modelsDir.exists()) await modelsDir.delete(recursive: true);
    } catch (e) {
      debugPrint("Cleanup error during cancellation: $e");
    }
  }
}
