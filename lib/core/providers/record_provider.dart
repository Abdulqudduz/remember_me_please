import 'dart:async';
import 'package:flutter/material.dart';
import 'package:remember_me_please/core/services/audio_service.dart';

class RecordProvider extends ChangeNotifier {
  final AudioService _audioService;
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;

  RecordProvider(this._audioService);

  bool get isRecording => _isRecording;

  String get recordingTime {
    final minutes = _recordDuration.inMinutes.toString().padLeft(2, '0');
    final seconds = (_recordDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    try {
      if (await _audioService.checkRecordPermission()) {
        await _audioService.start();
        _isRecording = true;
        _recordDuration = Duration.zero;
        _startTimer();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // Must return Future<String?> to hand off to the pipeline
  Future<String?> stopRecording() async {
    final path = await _audioService.stop();
    _isRecording = false;
    _timer?.cancel();
    notifyListeners();
    return path;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
