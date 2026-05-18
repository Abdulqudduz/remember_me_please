import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remember_me_please/core/providers/record_provider.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';
import 'package:remember_me_please/data/models/reminder_model.dart';
import 'package:remember_me_please/core/widgets/feature_card.dart';
import 'package:remember_me_please/core/widgets/recording_modal.dart';
import 'package:remember_me_please/features/conversations/pages/provider/conversation_provider.dart';
import 'package:remember_me_please/features/home/providers/reminder_provider.dart';
import 'package:remember_me_please/features/home/widgets/reminder_carousel.dart';
import 'package:remember_me_please/features/people/pages/camera_view_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePageContent();
  }
}

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      children: [
        _buildHeader(context),
        const SizedBox(height: 32),
        _buildSectionHeader('Up Next'),
        const SizedBox(height: 16),
        Consumer<ReminderProvider>(
          builder: (context, provider, _) {
            final activeList = provider.activeReminders;

            if (activeList.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No pending reminders!\nEnjoy your day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ReminderCarousel(
              reminders: activeList,
              onComplete: (int id) {
                provider.completeReminder(id);
              },
              onView: (reminder) => _showReminderDetails(context, reminder),
            );
          },
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('Quick Actions'),
        const SizedBox(height: 16),
        Consumer2<RecordProvider, ConversationProvider>(
          builder: (context, recordProvider, conversationProvider, _) {
            return FeatureCard(
              icon: Icons.mic,
              label: 'Record this conversation',
              sublabel: 'Start recording',
              color: AppColors.primary,
              isHorizontal: true,
              onTap: () async {
                try {
                  await recordProvider.startRecording();

                  if (!context.mounted) return;

                  showRecordingModal(
                    context,
                    onRecordFinished: () async {
                      try {
                        // Tell RecordProvider to stop and give us the saved file path
                        String? savedAudioPath = await recordProvider
                            .stopRecording();

                        // If it successfully saved, hand that path over to the ConversationProvider
                        if (savedAudioPath != null) {
                          conversationProvider.enqueueAudioProcess(
                            savedAudioPath,
                          );
                        }

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Audio saved! Processing in background...',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Stop error: $e');
                      }
                    },
                  );
                } catch (e, stack) {
                  debugPrint('Start recording failed: $e');
                  debugPrintStack(stackTrace: stack);
                }
              },
            );
          },
        ),
        const SizedBox(height: 16),
        FeatureCard(
          icon: Icons.photo_camera,
          label: 'Who is with me?',
          sublabel: 'Identify them',
          color: AppColors.tertiaryContainer,
          onColor: AppColors.onTertiaryContainer,
          isHorizontal: true,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CameraViewPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Saturday, April 18",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
        letterSpacing: -0.5,
      ),
    );
  }

  void _showReminderDetails(BuildContext context, ReminderModel reminder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Replaced hardcoded Colors.transparent with AppColors.transparent to match design system
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      size: 32,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: 32,
                      color: AppColors.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                reminder.time.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: reminder.brandColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                reminder.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {
                    final provider = Provider.of<ReminderProvider>(
                      context,
                      listen: false,
                    );
                    provider.completeReminder(reminder.id);
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: reminder.brandColor,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Mark as done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
