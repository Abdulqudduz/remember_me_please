import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remember_me_please/features/llm_model_download/page/configs/constants.dart';

class DownloadService {
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
        url: supportingModelsZipUrl,
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
