import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final String sender;
  final String text;
  final String time;
  final bool isMe;
  final String? avatarUrl;

  const ChatBubble({
    super.key,
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe) ...[
              if (avatarUrl != null)
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(avatarUrl!),
                )
              else
                const CircleAvatar(radius: 20, child: Icon(Icons.person)),
              const SizedBox(width: 12),
            ],
            Text(
              sender,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isMe ? AppColors.onSurface : AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(time, style: Theme.of(context).textTheme.bodySmall),
            if (isMe) ...[
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null
                    ? const Text(
                        'Me',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.primaryContainer
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(20),
            ),
            boxShadow: isMe
                ? null
                : [
                    BoxShadow(
                      // Replaced hardcoded Colors.black with AppColors.black to match design system
                      color: AppColors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isMe ? AppColors.onPrimaryContainer : AppColors.onSurface,
              fontSize: 20,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
