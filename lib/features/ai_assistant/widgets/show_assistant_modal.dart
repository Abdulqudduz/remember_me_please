import 'package:flutter/material.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';
import 'package:remember_me_please/features/ai_assistant/widgets/ai_assistant_modal.dart';

/// Public entry point
/// Opens the AI assistant as a full-height draggable bottom sheet.
///
/// Pass [conversationContext] (a raw JSON string of a conversation transcript)
/// when opening from the ConversationDetailPage "Ask about" button so the LLM
/// answers questions grounded in that specific conversation.
void showAIAssistantModal(BuildContext context, {String? conversationContext}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (context) =>
        AIAssistantModal(conversationContext: conversationContext),
  );
}
