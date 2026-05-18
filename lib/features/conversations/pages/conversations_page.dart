import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remember_me_please/data/models/conversation_model.dart';
import 'package:remember_me_please/data/sources/local/objectbox_service.dart';
import 'package:remember_me_please/features/conversations/pages/provider/conversation_provider.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';
import 'package:remember_me_please/features/conversations/widgets/conversation_card.dart';
import 'conversation_detail_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  late final Stream<List<ConversationModel>> _conversationStream;

  @override
  void initState() {
    super.initState();
    final objectBoxService = ObjectBoxService();
    _conversationStream = objectBoxService.watchConversations();
  }

  String _formatDate(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<ConversationModel>>(
        stream: _conversationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final dbConversations = snapshot.data ?? [];

          return Consumer<ConversationProvider>(
            builder: (context, provider, child) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                children: [
                  // The processing card
                  if (provider.isProcessing) ...[
                    ConversationCard(
                      name: 'AI Processing...',
                      timeLabel: 'Just now',
                      summary: provider.statusMessage,
                      avatarUrl: null, // Handle case where avatar might be empty
                      tags: const ['Processing'],
                      showViewDetails: false,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please wait until the AI finishes processing this conversation.',
                            ),
                            // Replaced hardcoded Colors.orange with AppColors.orange to match design system
                            backgroundColor: AppColors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // The real database cards
                  ...dbConversations.map((conv) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: ConversationCard(
                        name: conv.shortTitle,
                        timeLabel: _formatDate(conv.createdAt),
                        summary: conv.summary,
                        tags: conv.tags.isNotEmpty
                            ? conv.tags
                            : ['Conversation'],
                        showViewDetails: false,
                        avatarUrl: conv
                            .personImagePath, // Passes the image from ObjectBox!
                        onTap: () => _navigateToDetail(context, conv),
                      ),
                    );
                  }).toList(),

                  // Empty state fallback
                  if (dbConversations.isEmpty && !provider.isProcessing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          "No conversations recorded yet.",
                          // Replaced hardcoded Colors.grey with AppColors.grey to match design system
                          style: TextStyle(fontSize: 16, color: AppColors.grey),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, ConversationModel conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ConversationDetailPage(conversation: conversation),
      ),
    );
  }
}
