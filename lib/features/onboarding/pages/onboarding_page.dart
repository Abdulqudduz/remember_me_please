import 'package:flutter/material.dart';
import 'package:remember_me_please/features/llm_model_download/page/llm_model_download_page.dart';
import 'dart:io' show Platform;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';

class OnboardingSession {
  static Route _createRoute(Widget page) {
    return MaterialPageRoute(builder: (context) => page);
  }

  static void navigateNext(BuildContext context, Widget nextPage) {
    Navigator.of(context).push(_createRoute(nextPage));
  }
}

class WelcomeOnboardingPage extends StatelessWidget {
  const WelcomeOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: _OnboardingLayout(
        index: 0,
        title: 'Remember Me',
        subtitle: 'Never lose the moments that matter.',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBSsXdwQLTEWqDj-sqPYrSukAEMoXsmfeUw4a-dwBRv8IhJRMpYb9AvQVqYne_NnJlGz5rTaf4_73jg9-sn11McmchsgbPcbRWVY5KpyfBGtMll6kca3Yc6q5tieYQK-2UTzIj-FLwYgqMPIhIXhqV8XvP9viIRRLMp_l_swKGhcntpTvmI6yxoZVktdr0u8He4f5E4DQfmU4x8pB_S8CgBtPvSDjM3OCortKyxACRbUVJb3MfZr3y40NBthbKu4ZmAXB5hlfuXGw',
        isFirstPage: true,
        onNext: () => OnboardingSession.navigateNext(
          context,
          const PeopleOnboardingPage(),
        ),
      ),
    );
  }
}

class PeopleOnboardingPage extends StatelessWidget {
  const PeopleOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: _OnboardingLayout(
        index: 1,
        title: 'Remember the people you love',
        subtitle:
            'We help you remember names, relationships, and important details.',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDB27qSm5sbLNLR6e2BYDBMJMmQM9gdssZorC49cbMGEEEIb4cb3FJ-7CXbN0JcoSER-QSvxzbzT6zlE9WOG2K8AlVJYQt9YeJvWFA5q5Z2Ig5h795OITTVqQDSJ8FLcEXNv_cSkObZTd_sI2vGDDa4ALdav4ddaByrkWY7EOmUfY_mS1U_FgfW5xyqoAXxOf7F_wldMouoPTohgB5iaBxhpxr2KhlEIAz3xR0skdr21whXP5L5sEQYkZ_cSAQ9yIpBhniQtQ7ujw',
        onNext: () => OnboardingSession.navigateNext(
          context,
          const ConversationsOnboardingPage(),
        ),
      ),
    );
  }
}

class ConversationsOnboardingPage extends StatelessWidget {
  const ConversationsOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: _OnboardingLayout(
        index: 2,
        title: 'Never forget a conversation again',
        subtitle: 'Save and revisit meaningful conversations anytime',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAlVoSm9apsiN84QwWGJuzl0qkoaLLS5bDs4mmbHM3ajTye4XFGHPZQGN-PHCRdjQYvDBAlEe7xd1o0H5_as9g-yLaPrApl0WhncBWIizzuneIRenSIpCIJa2tOpu4MdyeB7C-HRcz5FIT01BZ5Bn7CzUBef4pWMrkSlxfn0GnNADWhc4-DLliSTV8raSxHSQcPtlwV9o2BIDDaAonWtMP_fcWE7UO8mMsMBhKh_czfyr2uVS_btQ_bzdf0zC_wY1fFNsZGCgfTdA',
        isLastPage: true,
        onNext: () => OnboardingSession.navigateNext(
          context,
          const LlmModelDownloadPage(),
        ),
      ),
    );
  }
}

class _OnboardingLayout extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool isFirstPage;
  final bool isLastPage;
  final VoidCallback onNext;

  const _OnboardingLayout({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.isFirstPage = false,
    this.isLastPage = false,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isFirstPage) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width - 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      // Replaced hardcoded Colors.black with AppColors.black to match design system
                      color: AppColors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
        Positioned(
          bottom: 48,
          left: 24,
          right: 24,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == i ? 12 : 8,
                    height: index == i ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == i
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastPage ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isFirstPage)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: CircleAvatar(
              // Replaced hardcoded Colors.black with AppColors.black to match design system
              backgroundColor: AppColors.black.withValues(alpha: 0.1),
              child: IconButton(
                icon: Icon(
                  Platform.isIOS ? Icons.arrow_back_ios_new : Icons.arrow_back,
                  color: AppColors.surfaceContainerLow,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
      ],
    );
  }
}
