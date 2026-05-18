import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

class ConversationCard extends StatelessWidget {
  final String name;
  final String timeLabel;
  final String summary;
  final String? imageUrl;
  final List<String>? tags;
  final bool showViewDetails;
  final VoidCallback? onTap;

  const ConversationCard({
    super.key,
    required this.name,
    required this.timeLabel,
    required this.summary,
    this.imageUrl,
    this.tags,
    this.showViewDetails = true,
    this.onTap,
    required avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      // Replaced hardcoded Colors.transparent with AppColors.transparent to match design system
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: BoxDecoration(
            color: showViewDetails
                ? AppColors.surfaceContainerLow
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(32),
            boxShadow: showViewDetails
                ? null
                : [
                    BoxShadow(
                      color: AppColors.onBackground.withValues(alpha: 0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeLabel.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name.startsWith('Talk with') ? name : name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: showViewDetails
                                    ? null
                                    : AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (imageUrl != null)
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.surfaceVariant,
                      backgroundImage: NetworkImage(imageUrl!),
                    )
                  else
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onBackground.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: showViewDetails ? null : 2,
                  overflow: showViewDetails ? null : TextOverflow.ellipsis,
                ),
              ),
              if (tags != null && tags!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags!
                      .map((tag) => _buildTag(context, tag))
                      .toList(),
                ),
              ],
              if (showViewDetails) ...[
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'View Details',
                  icon: Icons.visibility_outlined,
                  onPressed: onTap ?? () {},
                  isFullWidth: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String tag) {
    final isSpecial =
        tag.toLowerCase().contains('dinner') ||
        tag.toLowerCase().contains('meds');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSpecial
            ? AppColors.secondaryContainer
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isSpecial
              ? AppColors.onSecondaryContainer
              : AppColors.onSurface,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
