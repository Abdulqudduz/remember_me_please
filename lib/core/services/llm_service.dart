import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remember_me_please/core/utils/llm_prompt_builder.dart';
import 'package:remember_me_please/features/llm_model_download/page/constants/constants.dart';

class LlmService {
  static final LlmService _instance = LlmService._internal();
  factory LlmService() => _instance;
  LlmService._internal();

  InferenceModel? _model;
  dynamic
  _session; // Use dynamic to support different Gemma API versions (InferenceChat / InferenceSession)

  bool _isModelLoaded = false;
  bool _isGenerating = false;

  Future<void> initializeModel() async {
    if (_isModelLoaded) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelPath = '${appDir.path}/$modelName';
      final modelFile = File(modelPath);

      if (!modelFile.existsSync()) {
        throw Exception("Gemma model not found at $modelPath");
      }

      // Link the local file to the engine using the static installation pipeline
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromFile(modelPath).install();

      // Safely initialize and fetch the globally linked active model template
      _model ??=
          await FlutterGemma.getActiveModel(
            maxTokens: 4096, // Safe context window size
            preferredBackend: PreferredBackend
                .cpu, // CPU is safer for avoiding memory crashes
          ).timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw Exception('Model loading timed out.'),
          );

      // Create persistent session interface directly out of the active model wrapper
      _session ??= await _model!.createSession(
        temperature: 0.7, // Good balance for data extraction
      );

      _isModelLoaded = true;
      debugPrint("🧠 Gemma Brain successfully booted up!");
    } catch (e) {
      _isModelLoaded = false;
      _model = null;
      _session = null;
      throw Exception("Failed to initialize Gemma: $e");
    }
  }

  /// Extracts the JSON if Gemma accidentally wraps it in markdown
  String _cleanJsonResponse(String rawResponse) {
    String cleaned = rawResponse.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  /// Processes the transcript and returns a parsed Dart Map
  Future<Map<String, dynamic>?> processEnhancedTranscript(
    String rawJson,
    String detectedFaceName,
  ) async {
    if (!_isModelLoaded) await initializeModel();
    if (_isGenerating || _session == null) return null;

    _isGenerating = true;

    try {
      // Clear history so past transcripts don't confuse the current one
      await _session!.clearHistory();

      // Build the strict JSON prompt
      final promptText = LlmPromptBuilder.buildEnhancedTranscriptPrompt(
        rawJson,
        detectedFaceName,
      );

      // Add the prompt to the chat sequence
      await _session!.addQueryChunk(
        Message.text(text: promptText, isUser: true),
      );

      // NON-STREAMING: Directly await the full string output response
      final fullResponse = await _session!.getResponse();

      if (fullResponse.isEmpty) {
        throw Exception("Gemma returned an empty response.");
      }

      // Clean up the string to ensure it's raw JSON and parse it
      final cleanJsonString = _cleanJsonResponse(fullResponse);
      return jsonDecode(cleanJsonString);
    } catch (e) {
      debugPrint("Gemma Generation Error: $e");
      return null;
    } finally {
      _isGenerating = false;
    }
  }

  /// Clean up memory when app closes
  Future<void> dispose() async {
    await _session?.close();
    await _model?.close();
    _model = null;
    _session = null;
    _isModelLoaded = false;
  }

  /// Runs the RAG pipeline and streams the assistant's response token by token.
  Future<void> generateAssistantResponse({
    required String prompt,
    required void Function(String token) onToken,
    required void Function() onDone,
    required void Function(Object error) onError,
  }) async {
    // Ensure the model is loaded before attempting generation
    if (!_isModelLoaded) {
      try {
        await initializeModel();
      } catch (e) {
        onError(e);
        return;
      }
    }

    // Guard against concurrent generation requests
    if (_isGenerating || _session == null) {
      onError(Exception('Model is busy or not ready.'));
      return;
    }

    _isGenerating = true;

    try {
      // Clear previous chat history so the RAG context is the only input
      await _session!.clearHistory();

      // Add the fully-formed RAG prompt as the user turn
      await _session!.addQueryChunk(Message.text(text: prompt, isUser: true));

      // STREAMING: Iterate through chunks asynchronously as the model generates them
      await for (final String chunk in _session!.getResponseAsync()) {
        onToken(chunk);
      }

      _isGenerating = false;
      onDone();
    } catch (e) {
      _isGenerating = false;
      onError(e);
    }
  }
}
