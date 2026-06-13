// Singleton service that wraps the Kokoro int8 ONNX model via sherpa_onnx.
// The model is expected to be pre-downloaded by the user into the application
// documents directory at: <appDir>/models/kokoro_int8_onnx/
// This service does NOT copy assets from the bundle — it reads directly from
// the local file system path.
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remember_me_please/core/config/constants.dart';
import 'package:remember_me_please/core/utils/wav_helper.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// Singleton service for offline text-to-speech using the Kokoro int8 model.
///
/// Call [init] once before using [generateAndSaveAudio]. The service
/// is safe to call [init] multiple times — subsequent calls are no-ops.
class TtsService {
  // Private singleton constructor
  static final TtsService _instance = TtsService._internal();

  factory TtsService() => _instance;

  TtsService._internal();

  // The underlying sherpa_onnx TTS engine instance (nullable until init completes)
  sherpa_onnx.OfflineTts? _tts;

  // Dedicated audio player for TTS playback
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Cache to store generated audio paths by text hash
  final Map<String, String> _audioCache = {};

  // Flag to avoid re-initializing on repeated calls
  bool _isInitialized = false;

  /// Expose the player state stream so UI can react
  Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;

  /// Expose current playing state
  bool get isPlaying => _audioPlayer.state == PlayerState.playing;

  /// Initializes the Kokoro int8 TTS model from the local documents directory.
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize native sherpa_onnx bindings on the main isolate
    sherpa_onnx.initBindings();

    // The audio context is explicitly configured to override the physical silent switch
    // on devices and lower the volume of background audio. This guarantees that speech
    // notifications remain audible even if the user is listening to music or has muted the ringer.
    try {
      final context = AudioContextConfig(
        route: AudioContextConfigRoute.speaker,
        focus: AudioContextConfigFocus.duckOthers,
        respectSilence: false,
        stayAwake: true,
      ).build();
      await AudioPlayer.global.setAudioContext(context);
      await _audioPlayer.setAudioContext(context);
    } catch (e) {
      debugPrint('TtsService: Error setting AudioContext: $e');
    }

    final appDir = await getApplicationDocumentsDirectory();
    // print('App directory: ${appDir.path}');
    // print('----- Contents -----');

    // final items = appDir.listSync(recursive: true);

    // for (final item in items.where(
    //   (item) => item is Directory || item.path.toLowerCase().contains('koroko'),
    // )) {
    //   print(item.path);
    // }

    final kokoroPath = '${appDir.path}$kKokoroPath';

    debugPrint('TtsService: Loading Kokoro model from $kokoroPath');

    final modelDir = Directory(kokoroPath);
    if (!modelDir.existsSync()) {
      debugPrint(
        'TtsService: Model directory not found at $kokoroPath. '
        'TTS will be unavailable until the model is downloaded.',
      );
      return;
    }

    final ttsConfig = sherpa_onnx.OfflineTtsConfig(
      model: sherpa_onnx.OfflineTtsModelConfig(
        kokoro: sherpa_onnx.OfflineTtsKokoroModelConfig(
          model: '$kokoroPath$kModelName',
          voices: '$kokoroPath$kVoicesName',
          tokens: '$kokoroPath$kTokensName',
          dataDir: '$kokoroPath$kDataDirName',
        ),
        numThreads: 1,
        debug: kDebugMode, // Only enable verbose logging in debug builds
      ),
    );

    try {
      _tts = sherpa_onnx.OfflineTts(ttsConfig);
      _isInitialized = true;
      debugPrint('TtsService: Kokoro model initialized successfully.');
    } catch (e) {
      debugPrint('TtsService: Failed to initialize Kokoro model: $e');
      _tts = null;
      _isInitialized = false;
    }
  }

  /// Speaks the given text using the local TTS engine.
  /// Prioritizes the explicitly provided [audioPath] if it exists.
  /// Falls back to the internal cache if generated previously in this session.
  /// Generates a new WAV file and plays it as a last resort.

  Future<String?> speak(String text, {String? audioPath}) async {
    if (isPlaying) {
      await stop();
    }

    // Check the explicitly passed audio path first

    if (audioPath != null) {
      if (File(audioPath).existsSync()) {
        debugPrint('TtsService: Playing from actual path: $audioPath');
        try {
          await _audioPlayer.play(DeviceFileSource(audioPath));
          return audioPath;
        } catch (e) {
          debugPrint('TtsService: Error playing actual audio: $e');
        }
      } else {
        debugPrint(
          'TtsService: Provided audio path does not exist: $audioPath',
        );
      }
    }

    // Check the internal session cache for previously generated audio for this exact text

    final textHash = md5.convert(utf8.encode(text.trim())).toString();
    final cachedAudioPath = _audioCache[textHash];

    if (cachedAudioPath != null && File(cachedAudioPath).existsSync()) {
      debugPrint('TtsService: Playing from cache: $cachedAudioPath');
      try {
        await _audioPlayer.play(DeviceFileSource(cachedAudioPath));
        return cachedAudioPath;
      } catch (e) {
        debugPrint('TtsService: Error playing cached audio: $e');
      }
    }
    // Fallback to generating it right now if it's not cached. This is the slowest path but guarantees playback.
    if (text.trim().isEmpty) return null;

    final appDir = await getApplicationDocumentsDirectory();

    final generatedAudioPath = await generateAndSaveAudio(
      text: text,
      pathToSaveAudio: appDir,
    );

    if (generatedAudioPath != null && File(generatedAudioPath).existsSync()) {
      _audioCache[textHash] =
          generatedAudioPath; // Save it to cache for next time
      await _audioPlayer.play(DeviceFileSource(generatedAudioPath));
      return generatedAudioPath;
    } else {
      debugPrint('TtsService: Failed to generate audio for playback.');
    }
  }

  /// Stops current TTS playback.
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  /// Generates speech audio for [text] and saves it as a WAV file.
  Future<String?> generateAndSaveAudio({
    required String text,
    required Directory pathToSaveAudio,
  }) async {
    if (!_isInitialized || _tts == null) {
      debugPrint(
        'TtsService: generateAndSaveSummaryAudio called but engine is not initialized.',
      );
      return null;
    }

    if (text.trim().isEmpty) return null;

    try {
      debugPrint(
        'TtsService: Generating audio for text (${text.length} chars)',
      );
      final result = _tts!.generate(text: text.trim());

      // The ONNX model returns raw PCM float samples. We must convert these into a standard
      // WAV format by adding the appropriate headers so the audio player can decode the stream.
      final wavBytes = WavHelper.pcmToWav(result.samples, result.sampleRate);
      final fileName =
          'summary_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      final outputFile = File('${pathToSaveAudio.path}/$fileName');
      await outputFile.writeAsBytes(wavBytes);
      debugPrint('TtsService: Audio saved to ${outputFile.path}');
      return outputFile.path;
    } catch (e) {
      debugPrint('TtsService: Error during audio generation: $e');
      return null;
    }
  }

  /// Releases native resources held by the TTS engine.
  void dispose() {
    _audioPlayer.dispose();
    _tts?.free();
    _tts = null;
    _isInitialized = false;
    debugPrint('TtsService: Disposed.');
  }
}
