import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';
import 'package:remember_me_please/core/widgets/ai_assistant_modal.dart';
import 'package:remember_me_please/core/widgets/app_scaffold.dart';
import 'package:remember_me_please/data/models/conversation_model.dart';
import 'package:remember_me_please/core/widgets/audio_player_widget.dart';
import 'package:remember_me_please/features/conversations/widgets/chat_bubble.dart';
import 'package:remember_me_please/core/services/tts_service.dart';

class ConversationDetailPage extends StatefulWidget {
  final ConversationModel conversation;

  const ConversationDetailPage({super.key, required this.conversation});

  @override
  State<ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  // Controls scroll position for the back-to-top button
  late ScrollController _scrollController;
  bool _showBackToTopButton = false;

  // Tracks whether the summary audio is currently playing
  bool _isSummaryPlaying = false;
  late StreamSubscription<PlayerState> _ttsSubscription;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()
      ..addListener(() {
        // Show the button if the user scrolls past 300 pixels
        setState(() {
          _showBackToTopButton = _scrollController.offset >= 300;
        });
      });

    _isSummaryPlaying = TtsService().isPlaying;

    // Listen to the TTS service player's state so the button icon updates correctly
    _ttsSubscription = TtsService().playerStateStream.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isSummaryPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ttsSubscription.cancel();
    super.dispose();
  }

  // Scrolls the page smoothly back to the top
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  /// Toggles playback of the TTS-generated summary audio.
  ///
  /// Uses the global TtsService which manages caching and state.
  Future<void> _toggleSummaryPlayback() async {
    if (_isSummaryPlaying) {
      // Pause/Stop if currently playing
      await TtsService().stop();
    } else {
      // Play via the TTS service (generates if needed)
      await TtsService().speak(widget.conversation.summary);
    }
  }

  /// Opens the AI assistant modal with the conversation transcript as context.
  ///
  /// This allows the user to ask targeted questions about this specific
  /// conversation. The transcriptJson is injected directly into the LLM prompt,
  /// bypassing the global ObjectBox RAG search.
  void _openAskAboutModal() {
    showAIAssistantModal(
      context,
      conversationContext: widget.conversation.transcriptJson.isNotEmpty
          ? widget.conversation.transcriptJson
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Parse the stored JSON transcript for the chat bubble list
    List<dynamic> transcriptItems = [];
    if (widget.conversation.transcriptJson.isNotEmpty) {
      try {
        transcriptItems = jsonDecode(widget.conversation.transcriptJson);
      } catch (e) {
        debugPrint('ConversationDetailPage: Error parsing transcript JSON: $e');
      }
    }

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.conversation.shortTitle,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),

      // Back-to-top FAB
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showBackToTopButton ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !_showBackToTopButton,
          child: FloatingActionButton(
            onPressed: _scrollToTop,
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimaryContainer,
            elevation: 4,
            child: const Icon(Icons.arrow_upward),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('What was discussed'),
              const SizedBox(height: 16),
              // The summary card now contains wired playback and Ask About buttons
              _buildSummaryCard(context, widget.conversation.summary),
              const SizedBox(height: 48),

              _buildSectionTitle('Important Details'),
              const SizedBox(height: 16),
              if (widget.conversation.importantDetails.isNotEmpty)
                ...widget.conversation.importantDetails.map(
                  (detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildDetailItem(context, detail),
                  ),
                )
              else
                const Text(
                  'No important details identified.',
                  style: TextStyle(color: AppColors.grey, fontSize: 16),
                ),
              const SizedBox(height: 32),

              _buildSectionTitle('Conversation Audio'),
              const SizedBox(height: 16),
              AudioPlayerWidget(
                audioPath: widget.conversation.conversationAudioFilePathUrl,
              ),

              const SizedBox(height: 48),

              _buildSectionTitle('Full Conversation'),
              const SizedBox(height: 24),
              if (transcriptItems.isNotEmpty)
                ...transcriptItems.map((item) {
                  final speaker = item['speaker'] ?? 'Unknown';
                  final text = item['text'] ?? '';
                  final isMe = speaker == 'Speaker_0' || speaker == 'Me';

                  String finalAvatarUrl = '';
                  if (!isMe &&
                      speaker == widget.conversation.personName &&
                      widget.conversation.personImagePath != null) {
                    finalAvatarUrl = widget.conversation.personImagePath!;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: ChatBubble(
                      sender: isMe ? 'Me' : speaker,
                      text: text,
                      time: '',
                      isMe: isMe,
                      avatarUrl: finalAvatarUrl,
                    ),
                  );
                }).toList()
              else
                const Text(
                  'Transcript not available.',
                  style: TextStyle(color: AppColors.grey, fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  /// Builds the summary card with wired Read Aloud and Ask About buttons.
  Widget _buildSummaryCard(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                height: 1.5,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _toggleSummaryPlayback,
                  child: _buildActionButton(
                    context,
                    // Icon reflects current playback state
                    icon: _isSummaryPlaying ? Icons.stop : Icons.volume_up,
                    label: _isSummaryPlaying ? 'Stop' : 'Read aloud',
                    color: AppColors.primaryContainer,
                    onColor: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _openAskAboutModal,
                  child: _buildActionButton(
                    context,
                    icon: Icons.help_outline,
                    label: 'Ask about',
                    color: AppColors.secondaryContainer,
                    onColor: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.secondary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                height: 1.4,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required String title,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: AppColors.onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            time,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerLowest,
                foregroundColor: AppColors.tertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Add as a reminder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the styled pill button for Read Aloud and Ask About.
  ///
  /// Intentionally not wrapped in a GestureDetector here — the caller wraps it
  /// so the correct action is triggered per button.
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color onColor,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: onColor, size: 22),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
