// core/utils/llm_prompt_builder.dart

class LlmPromptBuilder {
  static String buildEnhancedTranscriptPrompt(
    String rawJsonTranscript,
    String detectedFaceName,
  ) {
    // We do the logic in Dart so the AI doesn't have to!
    String speakerInstructions;
    if (detectedFaceName == "Unknown") {
      speakerInstructions = """
      - Deduce speaker names strictly from the text (e.g., if someone says "Hi Anna", label them "Anna"). 
      - If no names are spoken, keep them as "Speaker_0" and "Speaker_1".
      """;
    } else {
      speakerInstructions =
          """
      - You MUST completely replace "Speaker_1" (or the non-primary speaker) with the name "$detectedFaceName" everywhere in the JSON.
      - You MUST deduce Speaker_0's name from context, or replace "Speaker_0" with "Me".
      - NEVER output "Speaker_1", it must be "$detectedFaceName".
      """;
    }

    return """You are a strict data processing backend. Output ONLY valid JSON.

TASK:
1. Correct typos in the input transcript text.
2. APPLY SPEAKER NAMES:
$speakerInstructions
3. Generate a 3-sentence "_conversationSummary" using the CORRECTED names.
4. Generate an "_importantDetails" array using the CORRECTED names.
5. Generate an "_actionItems" array using the CORRECTED names.
6. Generate a "_shortTitle" (Max 3 words).

INPUT TRANSCRIPT:
$rawJsonTranscript

EXPECTED JSON OUTPUT FORMAT:
{
  "transcript": [
    {
      "speaker": "Name goes here", 
      "text": "Corrected text here",
      "start_time": 0.0,
      "end_time": 0.0
    }
  ],
  "_conversationSummary": "...",
  "_importantDetails": ["..."],
  "_actionItems": ["..."],
  "_shortTitle": "..."
}""";
  }

  /// Builds a conversational RAG prompt for the AI Assistant.
  ///
  /// The prompt instructs the local LLM to answer the user's spoken query
  /// using only the retrieved ObjectBox context. The response must be plain
  /// prose so it can be displayed directly in the _ResponseView widget.
  static String buildRagPrompt({
    required String userQuery,
    required String retrievedContext,
  }) {
    return """You are a calm, helpful personal memory assistant for someone who needs reminders and memory support.

Your ONLY job is to answer the user's question using the CONTEXT below.
- Write a single, clear paragraph of 2-4 sentences.
- Do NOT use bullet points, JSON, or markdown formatting.
- If the context does not contain relevant information, say so honestly and gently.
- Never make up facts that are not in the context.

USER'S QUESTION:
"$userQuery"

CONTEXT FROM MEMORY:
$retrievedContext

YOUR RESPONSE:""";
  }

  /// Builds a focused prompt for questions about a specific conversation.
  ///
  /// Used by the "Ask about" button on the ConversationDetailPage. The raw
  /// [transcriptJson] from the conversation is injected as context so the LLM
  /// can answer questions that are grounded in that specific exchange.
  static String buildConversationContextPrompt({
    required String userQuery,
    required String transcriptJson,
  }) {
    return """You are a calm, helpful personal memory assistant.

The user is asking a question about a specific conversation they had. Answer using ONLY the transcript below.
- Write a single, clear paragraph of 2-4 sentences.
- Do NOT use bullet points, JSON, or markdown formatting.
- If the transcript does not contain the answer, say so honestly and gently.
- Never make up facts that are not in the transcript.

USER'S QUESTION:
"$userQuery"

CONVERSATION TRANSCRIPT (JSON):
$transcriptJson

YOUR RESPONSE:""";
  }
}
