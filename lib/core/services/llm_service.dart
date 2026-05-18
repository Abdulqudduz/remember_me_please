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

  final _gemma = FlutterGemmaPlugin.instance;
  InferenceModel? _model;
  InferenceChat? _chat;

  bool _isModelLoaded = false;
  bool _isGenerating = false;

  Future<void> initializeModel() async {
    if (_isModelLoaded) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();

      // Make sure this name exactly matches what your downloader saves!
      final modelPath = '${appDir.path}/$modelName';
      final modelFile = File(modelPath);

      if (!modelFile.existsSync()) {
        throw Exception("Gemma model not found at $modelPath");
      }

      // Point plugin to the model path (v0.13.2 syntax)
      // ignore: deprecated_member_use
      await _gemma.modelManager.setModelPath(modelPath);

      // Create model instance
      _model ??= await _gemma
          .createModel(
            preferredBackend: PreferredBackend
                .cpu, // CPU is safer for avoiding memory crashes
            modelType: ModelType.gemmaIt,
            maxTokens: 4096, // Safe context window size
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw Exception('Model loading timed out.'),
          );

      // Create persistent chat session
      _chat ??= await _model!.createChat(
        temperature: 0.7, // Good balance for data extraction
      );

      _isModelLoaded = true;
      debugPrint("🧠 Gemma Brain successfully booted up! (v0.13.2)");
    } catch (e) {
      _isModelLoaded = false;
      _model = null;
      _chat = null;
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
    if (_isGenerating || _chat == null) return null;

    _isGenerating = true;

    try {
      // Clear history so past transcripts don't confuse the current one
      await _chat!.clearHistory();

      // Build the strict JSON prompt
      final promptText = LlmPromptBuilder.buildEnhancedTranscriptPrompt(
        rawJson,
        detectedFaceName,
      );

      // Add the prompt to the chat
      await _chat!.addQuery(Message.text(text: promptText, isUser: true));

      // Use a Completer to gather the streaming tokens
      final completer = Completer<String>();
      final responseBuffer = StringBuffer();

      _chat!.generateChatResponseAsync().listen(
        (ModelResponse res) {
          if (res is TextResponse) {
            responseBuffer.write(res.token);
          }
        },
        onDone: () {
          // Stream finished, return the full collected string
          completer.complete(responseBuffer.toString());
        },
        onError: (error) {
          completer.completeError(error);
        },
      );

      // Wait for the stream to completely finish
      final fullResponse = await completer.future;

      if (fullResponse.isEmpty)
        throw Exception("Gemma returned an empty response.");

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
    await _model?.close();
    _model = null;
    _chat = null;
    _isModelLoaded = false;
  }

  /// Runs the RAG pipeline and streams the assistant's response token by token.
  ///
  /// The caller provides a [prompt] (already built by LlmPromptBuilder) and
  /// receives tokens via the [onToken] callback as they are generated. The
  /// [onDone] callback fires when the stream is complete, and [onError] receives
  /// any exception that occurred. This design lets the UI update progressively
  /// instead of waiting for the full response.
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
    if (_isGenerating || _chat == null) {
      onError(Exception('Model is busy or not ready.'));
      return;
    }

    _isGenerating = true;

    try {
      // Clear previous chat history so the RAG context is the only input
      await _chat!.clearHistory();

      // Add the fully-formed RAG prompt as the user turn
      await _chat!.addQuery(Message.text(text: prompt, isUser: true));

      // Stream tokens as they are generated by Gemma
      _chat!.generateChatResponseAsync().listen(
        (ModelResponse res) {
          if (res is TextResponse) {
            onToken(res.token);
          }
        },
        onDone: () {
          _isGenerating = false;
          onDone();
        },
        onError: (error) {
          _isGenerating = false;
          onError(error);
        },
        cancelOnError: true,
      );
    } catch (e) {
      _isGenerating = false;
      onError(e);
    }
  }
}
