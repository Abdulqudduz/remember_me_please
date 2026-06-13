import 'package:flutter/material.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Displays the mic icon and live speech-to-text transcript.
///
/// Starts listening immediately on mount. When the user taps "I am done
/// talking", it stops the listener and forwards the recognized text upstream.
class ListeningView extends StatefulWidget {
  final void Function(String text) onFinish;
  const ListeningView({required this.onFinish});

  @override
  State<ListeningView> createState() => _ListeningViewState();
}

class _ListeningViewState extends State<ListeningView> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    final available = await _speechToText.initialize(
      onStatus: (val) => debugPrint('SpeechToText status: $val'),
      onError: (val) => debugPrint('SpeechToText error: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speechToText.listen(
        onResult: (val) => setState(() {
          _text = val.recognizedWords;
        }),
      );
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: AppColors.onSurface,
                size: 28,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: AppColors.onPrimary, size: 48),
          ),
          const SizedBox(height: 40),
          Text(
            _isListening ? 'Listening...' : 'Initializing...',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w300,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _text.isEmpty
                ? "Take your time. I'm right here when you're ready to speak."
                : _text,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: FilledButton(
              onPressed: () {
                _speechToText.stop();
                // Pass the captured text up; fall back to a generic query if
                // speech recognition did not return anything.
                final finalText = _text.trim().isNotEmpty
                    ? _text.trim()
                    : 'What should I remember today?';
                widget.onFinish(finalText);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: const Text(
                'I am done talking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
