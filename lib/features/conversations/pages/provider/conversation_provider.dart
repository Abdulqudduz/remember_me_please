import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remember_me_please/core/services/active_person_tracker.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:remember_me_please/core/services/llm_service.dart';
import 'package:remember_me_please/core/services/tts_service.dart';
import 'package:remember_me_please/core/services/WhisperService.dart';
import 'package:remember_me_please/core/services/diarization_service.dart';
import 'package:remember_me_please/core/utils/file_helper.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';
import 'package:remember_me_please/data/models/conversation_model.dart';
import 'package:remember_me_please/data/models/reminder_model.dart';
import 'package:remember_me_please/data/sources/local/objectbox_service.dart';

class QueuedConversation {
  final String audioPath;
  final String detectedName;
  final String? detectedImagePath;

  QueuedConversation({
    required this.audioPath,
    required this.detectedName,
    this.detectedImagePath,
  });
}

class ConversationProvider extends ChangeNotifier {
  final WhisperService _whisperService = WhisperService();

  bool _isProcessing = false;
  String _statusMessage = "Ready";
  final Queue<QueuedConversation> _audioQueue = Queue<QueuedConversation>();

  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;
  int get itemsInQueue => _audioQueue.length;

  void enqueueAudioProcess(String recordedAudioPath) {
    // SNAPSHOT THE CAMERA DATA RIGHT NOW (When the user hits stop!)
    final personData = ActivePersonTracker().getActivePerson();

    // Add the audio AND the snapshot data to the queue together
    _audioQueue.add(
      QueuedConversation(
        audioPath: recordedAudioPath,
        detectedName: personData['name']!,
        detectedImagePath: personData['image'],
      ),
    );

    _statusMessage = "Queued (${_audioQueue.length} pending)";
    notifyListeners();
    _processNextInQueue();
  }

  Future<void> _processNextInQueue() async {
    if (_isProcessing || _audioQueue.isEmpty) return;

    _isProcessing = true;

    // Properly unpack the custom object from the queue
    final currentJob = _audioQueue.removeFirst();
    final currentAudioPath = currentJob.audioPath;
    final detectedName = currentJob.detectedName;
    final detectedImagePath = currentJob.detectedImagePath;

    _statusMessage =
        "Analyzing voices (1 of ${_audioQueue.length + 1} files)...";
    notifyListeners();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final paths = {
        'audioPath': currentAudioPath,
        'segPath': '${appDir.path}/models/speaker_diarization/model.onnx',
        'embPath':
            '${appDir.path}/models/speaker_diarization/3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx',
      };

      // PHASE 1: ISOLATE
      final slicedChunks = await Isolate.run(
        () => _diarizationAndSlicingWorker(paths),
      );

      // PHASE 2: WHISPER
      List<Map<String, dynamic>> conversationLog = [];
      final whisperModelPath =
          '${appDir.path}/models/whisper_base_en/ggml-base.en.bin';

      for (int i = 0; i < slicedChunks.length; i++) {
        final chunk = slicedChunks[i];

        _statusMessage =
            "Transcribing section ${i + 1} of ${slicedChunks.length}...";
        notifyListeners();

        final text = await _whisperService.transcribe(
          audioPath: chunk['path'],
          downloadedModelPath: whisperModelPath,
        );

        // Only add to the log if actual words were spoken
        if (text.trim().isNotEmpty) {
          conversationLog.add({
            "speaker": chunk['speaker'],
            "text": text.trim(),
            "start_time": chunk['start'],
            "end_time": chunk['end'],
          });
        }

        final chunkFile = File(chunk['path']);
        if (await chunkFile.exists()) await chunkFile.delete();
      }

      // ====================================================================
      // THE SHORT-CIRCUIT GUARD: Stop here if it was a 3-second accidental tap!
      // ====================================================================
      if (conversationLog.isEmpty) {
        debugPrint(
          "Pipeline Aborted: Recording was too short or no speech detected.",
        );

        // Delete the useless audio file so it doesn't waste phone storage!
        final originalAudio = File(currentAudioPath);
        if (await originalAudio.exists()) await originalAudio.delete();

        _statusMessage = "Audio discarded: No speech detected.";
        _isProcessing = false;
        notifyListeners();

        _processNextInQueue();
        return; // EXIT THE FUNCTION ENTIRELY! (Do not run Phase 3 or 4)
      }
      // ====================================================================

      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      final finalJsonOutput = encoder.convert(conversationLog);

      // PHASE 3: GEMMA (JSON Extraction & Correction)
      _statusMessage = "AI is structuring and correcting transcript...";
      notifyListeners();

      // We directly use 'detectedName' from the queue snapshot.
      final enhancedData = await LlmService().processEnhancedTranscript(
        finalJsonOutput,
        detectedName,
      );

      if (enhancedData != null) {
        final conversationSummary =
            enhancedData['_conversationSummary'] ?? 'No summary.';

        // PHASE 4.5: TTS GENERATION
        // Generate a spoken audio version of the summary text so the user
        // can listen to it on the detail page via "Read aloud".
        _statusMessage = "Generating audio summary...";
        notifyListeners();

        final audioSummaryPath =
            await TtsService().generateAndSaveSummaryAudio(conversationSummary);

        if (audioSummaryPath != null) {
          debugPrint(
            'Pipeline: TTS audio saved to $audioSummaryPath',
          );
        } else {
          debugPrint(
            'Pipeline: TTS generation skipped or failed. '
            'summaryAudioPath will be null.',
          );
        }

        final newConversation = ConversationModel(
          shortTitle: enhancedData['_shortTitle'] ?? 'New Recording',
          personName: detectedName, // Uses snapshot!
          personImagePath: detectedImagePath, // Uses snapshot!
          timeLabel: 'Just now',
          summary: conversationSummary,
          importantDetails: List<String>.from(
            enhancedData['_importantDetails'] ?? [],
          ),
          actionsItems: List<String>.from(enhancedData['_actionItems'] ?? []),
          transcriptJson: jsonEncode(enhancedData['transcript'] ?? []),
          conversationAudioFilePathUrl: currentAudioPath,
          // Store the TTS-generated WAV path (may be null if TTS unavailable)
          summaryAudioPath: audioSummaryPath,
        );

        // PHASE 5: SAVE TO OBJECTBOX
        final objectBoxService = ObjectBoxService();
        final savedId = objectBoxService.addConversation(newConversation);

        if (savedId > 0) {
          debugPrint('Pipeline: Successfully saved to database. ID: $savedId');

          // Extract the elements from the enhancedData['_actionItems'] array.
          // Convert each item into a ReminderModel and save it directly.
          if (enhancedData['_actionItems'] is List) {
            final actionItems = enhancedData['_actionItems'] as List;
            for (final item in actionItems) {
              if (item is String && item.trim().isNotEmpty) {
                final reminderText = item.trim();
                final lowerText = reminderText.toLowerCase();

                // Map keywords in the action item to appropriate ReminderIcon.
                ReminderIcon icon = ReminderIcon.notification;
                int brandColor = AppColors.primary.toARGB32();
                int containerColor = AppColors.primaryContainer.toARGB32();
                int onContainerColor = AppColors.onPrimaryContainer.toARGB32();

                if (lowerText.contains("pill") ||
                    lowerText.contains("medication") ||
                    lowerText.contains("medicine") ||
                    lowerText.contains("doctor") ||
                    lowerText.contains("dentist") ||
                    lowerText.contains("pharmacy") ||
                    lowerText.contains("take my") ||
                    lowerText.contains("take your")) {
                  icon = ReminderIcon.medication;
                  brandColor = AppColors.tertiary.toARGB32();
                  containerColor = AppColors.tertiaryContainer.toARGB32();
                  onContainerColor = AppColors.onTertiaryContainer.toARGB32();
                } else if (lowerText.contains("clean") ||
                    lowerText.contains("wash") ||
                    lowerText.contains("buy") ||
                    lowerText.contains("shop") ||
                    lowerText.contains("grocery") ||
                    lowerText.contains("groceries") ||
                    lowerText.contains("milk") ||
                    lowerText.contains("home") ||
                    lowerText.contains("house") ||
                    lowerText.contains("repair") ||
                    lowerText.contains("fix")) {
                  icon = ReminderIcon.home;
                  brandColor = AppColors.secondary.toARGB32();
                  containerColor = AppColors.secondaryContainer.toARGB32();
                  onContainerColor = AppColors.onSecondaryContainer.toARGB32();
                } else if (lowerText.contains("gym") ||
                    lowerText.contains("workout") ||
                    lowerText.contains("exercise") ||
                    lowerText.contains("run") ||
                    lowerText.contains("walk") ||
                    lowerText.contains("stretch") ||
                    lowerText.contains("fitness")) {
                  icon = ReminderIcon.fitness;
                  brandColor = AppColors.primary.toARGB32();
                  containerColor = AppColors.primaryContainer.toARGB32();
                  onContainerColor = AppColors.onPrimaryContainer.toARGB32();
                } else if (lowerText.contains("water") ||
                    lowerText.contains("drink") ||
                    lowerText.contains("hydrate")) {
                  icon = ReminderIcon.water;
                  brandColor = AppColors.primary.toARGB32();
                  containerColor = AppColors.primaryContainer.toARGB32();
                  onContainerColor = AppColors.onPrimaryContainer.toARGB32();
                } else if (lowerText.contains("call") ||
                    lowerText.contains("phone") ||
                    lowerText.contains("email") ||
                    lowerText.contains("contact") ||
                    lowerText.contains("alarm") ||
                    lowerText.contains("wake") ||
                    lowerText.contains("time")) {
                  icon = ReminderIcon.alarm;
                  brandColor = AppColors.primary.toARGB32();
                  containerColor = AppColors.primaryContainer.toARGB32();
                  onContainerColor = AppColors.onPrimaryContainer.toARGB32();
                }

                // Deduce reminder time from text patterns, otherwise default to "Upcoming".
                String reminderTime = "Upcoming";
                final timeRegex = RegExp(r'\b(?:at\s+)?(\d{1,2}(?::\d{2})?\s*(?:am|pm|AM|PM))\b');
                final match = timeRegex.firstMatch(reminderText);
                if (match != null) {
                  reminderTime = match.group(1) ?? "Upcoming";
                } else if (lowerText.contains("morning")) {
                  reminderTime = "Morning";
                } else if (lowerText.contains("afternoon")) {
                  reminderTime = "Afternoon";
                } else if (lowerText.contains("evening") || lowerText.contains("night")) {
                  reminderTime = "Evening";
                }

                // Create the ReminderModel entity.
                final newReminder = ReminderModel(
                  title: reminderText,
                  time: reminderTime,
                  iconIndex: icon.index,
                  brandColorValue: brandColor,
                  containerColorValue: containerColor,
                  onContainerColorValue: onContainerColor,
                  isCompleted: false,
                );

                // Save to ObjectBox reminder box directly.
                final reminderId = objectBoxService.addReminder(newReminder);
                if (reminderId > 0) {
                  debugPrint('Pipeline: Successfully saved auto reminder. ID: $reminderId');
                } else {
                  debugPrint('Pipeline: Failed to save auto reminder.');
                }
              }
            }
          }
        } else {
          debugPrint('Pipeline: Failed to save to database.');
        }
      }

      _statusMessage = "Processing complete!";
    } catch (e) {
      _statusMessage = "Pipeline Error: $e";
      debugPrint("Pipeline Error: $e");
    } finally {
      _isProcessing = false;
      notifyListeners();
      _processNextInQueue(); // Trigger the next queued item!
    }
  }
}

// ============================================================================
// BACKGROUND WORKER (ISOLATE THREAD)
// ============================================================================
// Only handles the Sherpa Diarization math. No complex Flutter bindings needed!
Future<List<Map<String, dynamic>>> _diarizationAndSlicingWorker(
  Map<String, String> paths,
) async {
  // Initialize pure FFI C++ bindings (100% safe in isolates)
  sherpa_onnx.initBindings();

  final audioPath = paths['audioPath']!;
  final segPath = paths['segPath']!;
  final embPath = paths['embPath']!;

  final diarizationService = DiarizationService();

  // Run Diarization
  final diarizationResult = await diarizationService.getSpeakerSegments(
    audioPath: audioPath,
    segmentationModelPath: segPath,
    embeddingModelPath: embPath,
  );

  final segments = diarizationResult['segments'];
  final waveData = diarizationResult['waveData'];

  List<Map<String, dynamic>> chunkDataList = [];
  final tempDir = Directory.systemTemp;

  // Slice Loop
  for (int i = 0; i < segments.length; ++i) {
    final segment = segments[i];

    int startSample = (segment.start * waveData.sampleRate).toInt();
    int endSample = (segment.end * waveData.sampleRate).toInt();

     if (endSample > waveData.samples.length) {
      endSample = waveData.samples.length;
    }
    if (startSample < 0) {
      startSample = 0;
    }
    if (startSample >= endSample) {
      continue;
    }

    Float32List chunk = Float32List.sublistView(
      waveData.samples,
      startSample,
      endSample,
    );

    String tempChunkPath =
        '${tempDir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}_$i.wav';

    await FileHelpers.saveFloat32ListToWav(
      chunk,
      waveData.sampleRate,
      tempChunkPath,
    );

    // Pass simple primitive data back to the main thread
    chunkDataList.add({
      'speaker': 'Speaker_${segment.speaker}',
      'start': double.parse(segment.start.toStringAsFixed(2)),
      'end': double.parse(segment.end.toStringAsFixed(2)),
      'path': tempChunkPath,
    });
  }

  return chunkDataList;
}
