import 'dart:io';
import 'package:flutter_archive/flutter_archive.dart';

class ZipExtractionService {
  static Future<void> extractModelsZip(String savedDirPath, String fileName) async {
    final zipFile = File('$savedDirPath/$fileName');
    final destinationDir = Directory('$savedDirPath/models');

    if (!destinationDir.existsSync()) {
      destinationDir.createSync(recursive: true);
    }

    if (!zipFile.existsSync()) {
      throw Exception("Zip file not found.");
    }

    await ZipFile.extractToDirectory(
      zipFile: zipFile,
      destinationDir: destinationDir,
      onExtracting: (zipEntry, progress) => ZipFileOperation.includeItem,
    );

    // Delete the heavy zip file after extraction
    if (zipFile.existsSync()) {
      zipFile.deleteSync();
    }
  }
}