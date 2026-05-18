import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AudioService {
  // The audio service is implemented as a singleton to ensure only one recording
  // or speech recognition session is active at a time across the entire application.
  static final AudioService _instance = AudioService._internal();

  AudioService._internal();

  factory AudioService() => _instance;

  final AudioRecorder _recorder = AudioRecorder();
  final SpeechToText _speech = SpeechToText();

  Future<bool> checkRecordPermission() async => await _recorder.hasPermission();

  Future<void> start() async {
    final appDir = await getApplicationDocumentsDirectory();
    final filePath =
        '${appDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

    // Safety check: ensure we aren't already recording
    if (await _recorder.isRecording()) return;

    // The recording is configured to use the WAV encoder to ensure proper file headers
    // are present for the Sherpa-ONNX engine. The sample rate is strictly set to 16kHz
    // and mono channel, which is the required input format for the transcription models.
    final recordConfig = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
    );
    await _recorder.start(recordConfig, path: filePath);
  }

  Future<String?> stop() async {
    return await _recorder.stop();
  }

  void dispose() => _recorder.dispose();

  // Speech to Text Integration
  Future<bool> initSTT() async => await _speech.initialize();

  Future<void> startListening(Function(String text) onResult) async {
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}
