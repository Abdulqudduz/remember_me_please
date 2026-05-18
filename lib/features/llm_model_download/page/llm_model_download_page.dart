import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remember_me_please/features/llm_model_download/provider/llm_download_page_provider.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';
import 'package:remember_me_please/core/widgets/app_scaffold.dart';
import 'package:remember_me_please/core/widgets/confirmation_dialog.dart';
import 'package:remember_me_please/features/navigation/pages/main_navigation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LlmModelDownloadPage extends StatelessWidget {
  const LlmModelDownloadPage({super.key});

  static void completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainNavigationPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        title: const Text('Download Required Models'),
      ),
      body: Consumer<LlmDownloadProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Info
                const Icon(
                  Icons.dns_rounded,
                  size: 60,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'A free HuggingFace account and ~6GB of storage are required '
                  '(Main LLM: 2.58GB, Support Models: 264MB).Note: If importing'
                  ' the main model locally, you must still download the support'
                  ' models. Please be patient; the import progress bar takes a'
                  ' moment to appear.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                // --- SECTION 1: GEMMA MODEL ---
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '1. Gemma 4 E2B IT LiteRT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          provider.gemmaStatusText,
                          style: TextStyle(
                            color: provider.gemmaState == ModelState.success
                                ? AppColors.green
                                : AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Progress Bar
                        if (provider.gemmaState == ModelState.downloading ||
                            provider.gemmaState == ModelState.success) ...[
                          LinearProgressIndicator(
                            value: provider.gemmaProgress?.progress ?? 0,
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Buttons
                        if (provider.gemmaState == ModelState.notStarted ||
                            provider.gemmaState == ModelState.failed)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.cloud_download),
                                  label: const Text('Download'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.onTertiary,
                                  ),
                                  onPressed: provider.isAnyDownloading
                                      ? null
                                      : () => provider.startGemmaDownload(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.folder),
                                  label: const Text('Import'),
                                  onPressed: provider.isAnyDownloading
                                      ? null
                                      : () => provider.importModelFromDevice(),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // --- SECTION 2: ADDITIONAL MODELS ---
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '2. Additional Models (Audio/TTS)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          provider.additionalStatusText,
                          style: TextStyle(
                            color:
                                provider.additionalState == ModelState.success
                                ? AppColors.green
                                : AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Progress Bar
                        if (provider.additionalState ==
                                ModelState.downloading ||
                            provider.additionalState == ModelState.extracting ||
                            provider.additionalState == ModelState.success) ...[
                          LinearProgressIndicator(
                            value: provider.additionalProgress?.progress ?? 0,
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Waiting text if not started
                        if (provider.additionalState == ModelState.notStarted ||
                            provider.additionalState == ModelState.failed)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "Starts automatically after Step 1.",
                              style: TextStyle(
                                color: AppColors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- GLOBAL ACTIONS ---
                if (provider.isAnyDownloading)
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.cancel, color: AppColors.white),
                          SizedBox(width: 8),
                          Text(
                            'Cancel All Downloads',
                            style: TextStyle(color: AppColors.white),
                          ),
                        ],
                      ),

                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ConfirmationDialog(
                            title: const Icon(
                              Icons.cancel_rounded,
                              color: AppColors.redAccent,
                              size: 60.0,
                            ),
                            content:
                                'Are you sure you want to cancel the download? Progress will be lost.',
                            confirmText: 'Yes, Cancel',
                            cancelText: 'No',
                            isDestructive: true,
                            onConfirm: () => provider.cancelCurrentDownload(),
                          ),
                        );
                      },
                    ),
                  ),

                if (provider.isEverythingComplete)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.green, // Highlight success
                    ),
                    onPressed: () => completeOnboarding(context),
                    child: const Text(
                      'Continue to App',
                      style: TextStyle(fontSize: 18, color: AppColors.white),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
