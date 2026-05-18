// core/widgets/audio_player_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remember_me_please/core/providers/playback_provider.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;

  const AudioPlayerWidget({super.key, required this.audioPath});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _fileExists = false;

  // Create a variable to hold the provider reference
  late PlaybackProvider _playbackProvider;

  @override
  void initState() {
    super.initState();

    // Grab the reference while the context is still perfectly safe and alive!
    // context.read() is the same as Provider.of(..., listen: false)
    _playbackProvider = context.read<PlaybackProvider>();

    _fileExists = File(widget.audioPath).existsSync();

    if (_fileExists) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playbackProvider.loadAudio(widget.audioPath);
      });
    }
  }

  @override
  void dispose() {
    // Use the safely saved reference instead of 'context'
    _playbackProvider.clearAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_fileExists) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "Audio file no longer available.",
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }

    return Consumer<PlaybackProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Play/Pause Button (No longer needs to pass the path)
              IconButton(
                icon: Icon(
                  provider.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 40,
                  color: AppColors.primary,
                ),
                onPressed: () => provider.togglePlayPause(),
              ),

              // Progress Slider & Timestamps
              // Progress Slider & Timestamps
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6.0,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14.0,
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          // Calculate the safe maximum duration
                          final double maxVal =
                              provider.totalDuration.inSeconds.toDouble() > 0
                              ? provider.totalDuration.inSeconds.toDouble()
                              : 1.0;

                          // Clamp the current value so it NEVER exceeds maxVal
                          final double safeValue = provider
                              .currentPosition
                              .inSeconds
                              .toDouble()
                              .clamp(0.0, maxVal);

                          return Slider(
                            value: safeValue, // Use the clamped safe value!
                            max: maxVal,

                            // Visual Guard: Disable if audio isn't loaded
                            onChanged: provider.totalDuration.inSeconds > 0
                                ? (value) {
                                    provider.updateDragPosition(
                                      Duration(seconds: value.toInt()),
                                    );
                                  }
                                : null,

                            // Send to native engine on release
                            onChangeEnd: provider.totalDuration.inSeconds > 0
                                ? (value) {
                                    provider.seek(
                                      Duration(seconds: value.toInt()),
                                    );
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            provider.formatDuration(provider.currentPosition),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            provider.formatDuration(provider.totalDuration),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
