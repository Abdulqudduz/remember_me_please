import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remember_me_please/features/llm_model_download/page/constants/constants.dart';

class HuggingFaceDownloadService {
  /// Enqueues the download natively and returns the Task ID.
  Future<String?> downloadModel(String token) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      // flutter_downloader handles the actual HTTP request and file writing natively
      final taskId = await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: appDir.path,
        fileName: modelName,
        headers: {
          'Authorization': 'Bearer $token',
        }, // Pass your OAuth token here
        showNotification:
            true, // Shows standard OS progress bar in notification tray
        openFileFromNotification: false,
      );

      return taskId;
    } catch (e) {
      throw Exception('Failed to enqueue download: $e');
    }
  }

  /// Helper to get all current download tasks
  Future<List<DownloadTask>> getActiveDownloads() async {
    return await FlutterDownloader.loadTasks() ?? [];
  }

  /// Helper to cancel a download
  Future<void> cancelDownload(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
  }

  /// Enqueues the supporting models zip from GitHub
  Future<String?> downloadSupportingModels() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final taskId = await FlutterDownloader.enqueue(
        url: "https://github.com/Abdulqudduz/remember_me_models/releases/download/v1.0.0/koroko_whisper_speaker_diarization_models.zip",
        savedDir: appDir.path,
        fileName: "models.zip",
        showNotification: true,
        openFileFromNotification: false,
      );
      return taskId;
    } catch (e) {
      throw Exception('Failed to enqueue supporting models: $e');
    }
  }
}
