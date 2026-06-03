import 'dart:io';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

class WhisperService {
  final WhisperController _controller = WhisperController();

  Future<String> transcribe({
    required String audioPath,
    required String downloadedModelPath,
  }) async {
    // Ask the package exactly where it expects the model to be saved
    final requiredInternalPath = await _controller.getPath(WhisperModel.baseEn);
    final requiredFile = File(requiredInternalPath);

    // If the model isn't in that exact spot, copy our downloaded one over there
    if (!await requiredFile.exists()) {
      final downloadedFile = File(downloadedModelPath);

      if (await downloadedFile.exists()) {
        await downloadedFile.copy(requiredInternalPath);
      } else {
        throw Exception(
          "Downloaded Whisper model not found at: $downloadedModelPath",
        );
      }
    }

    // Now run the transcription using the required enum parameter
    final response = await _controller.transcribe(
      model: WhisperModel.baseEn, // Now using the required enum
      audioPath: audioPath,
      lang: "en",
    );

    return response?.transcription.text ?? "No speech detected";
  }
}
