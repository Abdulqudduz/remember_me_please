import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remember_me_please/core/services/llm_service.dart';
import 'package:remember_me_please/core/services/tts_service.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';
import 'package:remember_me_please/core/utils/llm_prompt_builder.dart';
import 'package:remember_me_please/data/sources/local/objectbox_service.dart';

/// Runs the RAG pipeline while displaying a loading indicator.
///
/// On mount it retrieves context from ObjectBox, builds the LLM prompt via
/// LlmPromptBuilder, and streams the response from LlmService. Once the
/// stream is complete, it calls [onFinish] with the full response string.
///
/// When [conversationContext] is provided (non-null), the pipeline uses that
/// specific transcript instead of the ObjectBox RAG query.
class ThinkingView extends StatefulWidget {
  final String spokenText;
  // Optional transcript JSON from a specific conversation (for "Ask about")
  final String? conversationContext;
  final void Function(String response) onFinish;

  const ThinkingView({
    required this.spokenText,
    this.conversationContext,
    required this.onFinish,
  });

  @override
  State<ThinkingView> createState() => _ThinkingViewState();
}

class _ThinkingViewState extends State<ThinkingView> {
  final LlmService _llmService = LlmService();
  final ObjectBoxService _objectBoxService = ObjectBoxService();

  @override
  void initState() {
    super.initState();
    _runRagPipeline();
  }

  void _runRagPipeline() async {
    String prompt;

    if (widget.conversationContext != null &&
        widget.conversationContext!.isNotEmpty) {
      // The user tapped "Ask about" on a specific conversation, so use its
      // transcript JSON as context instead of the general ObjectBox query.
      prompt = LlmPromptBuilder.buildConversationContextPrompt(
        userQuery: widget.spokenText,
        transcriptJson: widget.conversationContext!,
      );
    } else {
      // General assistant flow: retrieve matching context from ObjectBox
      final context = _objectBoxService.retrieveContextForQuery(
        widget.spokenText,
      );
      prompt = LlmPromptBuilder.buildRagPrompt(
        userQuery: widget.spokenText,
        retrievedContext: context,
      );
    }

    // Stream the LLM response, accumulating tokens into a buffer
    final responseBuffer = StringBuffer();

    await _llmService.generateAssistantResponse(
      prompt: prompt,
      onToken: (token) => responseBuffer.write(token),
      onDone: () async {
        final result = responseBuffer.toString().trim();
        if (result.isNotEmpty) {
          final audioSummaryPath = await TtsService().generateAndSaveAudio(
            text: result,
            pathToSaveAudio: await getApplicationDocumentsDirectory(),
          );
          debugPrint('LLM response complete: $result');
        } else {
          debugPrint('LLM returned an empty response.');
        }
        // Provide a graceful fallback when the model returns nothing
        widget.onFinish(
          result.isNotEmpty
              ? result
              : 'I was unable to find a relevant answer in your memories.',
        );
      },
      onError: (error) {
        debugPrint('RAG pipeline error: $error');
        widget.onFinish(
          'Something went wrong while searching your memories. Please try again.',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.onPrimary,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Thinking...',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "I'm looking back through your memories and preparing a thoughtful response.",
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
