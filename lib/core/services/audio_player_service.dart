import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayerService() {
    _initAudioContext();
  }

  Future<void> _initAudioContext() async {
    try {
      final context = AudioContextConfig(
        route: AudioContextConfigRoute.speaker,
        focus: AudioContextConfigFocus.duckOthers,
        respectSilence: false,
        stayAwake: true,
      ).build();
      await _player.setAudioContext(context);
    } catch (e) {
      // Ignore
    }
  }

  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration> get durationStream => _player.onDurationChanged;
  Stream<PlayerState> get stateStream => _player.onPlayerStateChanged;

  Future<void> loadFile(String path) async {
    await _player.setSource(DeviceFileSource(path));
  }

  Future<void> resume() async => await _player.resume();
  Future<void> pause() async => await _player.pause();
  Future<void> stop() async => await _player.stop();
  Future<void> seek(Duration position) async => await _player.seek(position);

  // NEW: Releases the native resources back to Android
  Future<void> release() async => await _player.release();

  void dispose() {
    _player.dispose();
  }
}
