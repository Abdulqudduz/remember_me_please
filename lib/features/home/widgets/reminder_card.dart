import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/reminder_model.dart';

class ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final bool isActive;
  final VoidCallback? onComplete;
  final VoidCallback onView;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.isActive = true,
    this.onComplete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 300),
        child: Container(
          constraints: const BoxConstraints(minHeight: 160),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.onBackground.withValues(
                  alpha: isActive ? 0.06 : 0.02,
                ),
                blurRadius: isActive ? 32 : 16,
                offset: Offset(0, isActive ? 12 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 8,
                  child: Container(color: reminder.brandColor),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder.time.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: reminder.brandColor),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              reminder.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (isActive && onComplete != null) ...[
                              const Spacer(),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: onComplete,
                                    style: TextButton.styleFrom(
                                      backgroundColor: reminder.brandColor
                                          .withValues(alpha: 0.1),
                                      foregroundColor: reminder.brandColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text('I did this already'),
                                  ),

                                  // const SizedBox(width: 10),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: reminder.containerColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              reminder.icon,
                              color: reminder.onContainerColor,
                              size: 28,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: onView,
                            style: TextButton.styleFrom(
                              backgroundColor: reminder.brandColor.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: reminder.brandColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('View'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
