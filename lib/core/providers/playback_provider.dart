// core/providers/playback_provider.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:remember_me_please/core/services/audio_player_service.dart';

class PlaybackProvider extends ChangeNotifier {
  final AudioPlayerService _audioPlayerService;

  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _loadedAudioPath;

  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _stateSub;
  Duration? _dragPosition;

  PlaybackProvider(this._audioPlayerService) {
    _initStreams();
  }

  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _dragPosition ?? _currentPosition;
  Duration get totalDuration => _totalDuration;

  void _initStreams() {
    _positionSub = _audioPlayerService.positionStream.listen((p) {
      _currentPosition = p;
      notifyListeners();
    });

    _durationSub = _audioPlayerService.durationStream.listen((d) {
      _totalDuration = d;
      notifyListeners();
    });

    _stateSub = _audioPlayerService.stateStream.listen((state) {
      _isPlaying = state == PlayerState.playing;
      if (state == PlayerState.completed) {
        _currentPosition = Duration.zero;
        _isPlaying = false;
        _audioPlayerService.seek(Duration.zero); // Reset to start
      }
      notifyListeners();
    });
  }

  // Preloads the audio and grabs the duration
  Future<void> loadAudio(String audioPath) async {
    if (_loadedAudioPath == audioPath) return; // Already loaded

    _loadedAudioPath = audioPath;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _isPlaying = false;
    notifyListeners();

    try {
      await _audioPlayerService.loadFile(audioPath);
    } catch (e) {
      debugPrint("Audio load error: $e");
    }
  }

  Future<void> togglePlayPause() async {
    if (_loadedAudioPath == null) return;

    if (_isPlaying) {
      await _audioPlayerService.pause();
    } else {
      await _audioPlayerService.resume();
    }
  }

  Future<void> seek(Duration position) async {
    _dragPosition = null; // Clear the temporary drag state

    if (_totalDuration.inSeconds == 0) return;

    try {
      // Send the single command to the native engine
      await _audioPlayerService.seek(position);
    } catch (e) {
      // If a timeout happens in the background, catch it silently so the app doesn't crash!
      debugPrint("Seek safely ignored an engine error: $e");
    }
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // Updates the UI instantly while dragging without touching the native player
  void updateDragPosition(Duration position) {
    _dragPosition = position;
    notifyListeners();
  }

  Future<void> clearAudio() async {
    _loadedAudioPath = null;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _isPlaying = false;
    // Don't call notifyListeners() here since the widget is about to be destroyed anyway

    try {
      await _audioPlayerService.stop();
      await _audioPlayerService.release(); // Free up the Android OS memory!
    } catch (e) {
      debugPrint("Audio release error: $e");
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _audioPlayerService.dispose();
    super.dispose();
  }
}
