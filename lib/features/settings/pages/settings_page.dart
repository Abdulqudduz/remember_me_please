import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../widgets/settings_widgets.dart';
import '../providers/settings_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/language_provider.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPageBody();
  }
}

class SettingsPageBody extends StatelessWidget {
  const SettingsPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return AppScaffold(
      appBar: AppBar(
        surfaceTintColor: AppColors.transparent,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.primary,
              size: 28,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        backgroundColor: AppColors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            const SettingsSectionHeader(title: 'Region & Language'),
            SettingsTile(
              title: 'Language (Coming Soon)',
              subtitle: languageProvider.getCurrentLanguageName(context),
              icon: Icons.language,
              onTap: () {},
              enabled: false,
            ),
            const SettingsSectionHeader(title: 'Appearance'),
            _buildSegmentedControl(
              context,
              options: const ['Light', 'Dark', 'System'],
              selectedIndex: _getThemeIndex(themeProvider.themeMode),
              onTap: (index) {
                final modes = [
                  ThemeMode.light,
                  ThemeMode.dark,
                  ThemeMode.system,
                ];
                themeProvider.setThemeMode(modes[index]);
              },
            ),
            const SettingsSectionHeader(title: 'Audio Output'),
            SettingsSwitchTile(
              title: 'Voice playback (Coming Soon)',
              subtitle: 'App reads text aloud to you.',
              value: settingsProvider.tapToRead,
              onChanged: settingsProvider.toggleTapToRead,
              enabled: false,
            ),

            const SettingsSectionHeader(title: 'Smart Reminders'),
            SettingsSwitchTile(
              title: 'AI suggestions',
              subtitle: 'Predictive reminders.',
              value: settingsProvider.aiReminders,
              onChanged: settingsProvider.toggleAiReminders,
            ),
            SettingsSwitchTile(
              title: 'Tasks reminders',
              subtitle: 'Triggered by time.',
              value: settingsProvider.locationSuggestions,
              onChanged: settingsProvider.toggleLocationSuggestions,
            ),
            const SettingsSectionHeader(title: 'Accessibility'),
            const Text(
              'Text Size (Coming Soon)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: 0.5,
              child: _buildSegmentedControl(
                context,
                options: const ['Small', 'Medium', 'Large'],
                selectedIndex: _getSizeIndex(settingsProvider.textSize),
                onTap: (index) {},
              ),
            ),
            const SizedBox(height: 16),
            SettingsSwitchTile(
              title: 'High contrast',
              subtitle: 'Enhanced visibility.',
              value: settingsProvider.highContrast,
              onChanged: settingsProvider.toggleHighContrast,
            ),
            const SettingsSectionHeader(title: 'Data Control'),
            SettingsTile(
              title: 'Import data (Coming Soon)',
              subtitle: 'Restore from a local backup.',
              icon: Icons.file_download_rounded,
              onTap: () {},
              enabled: false,
            ),
            SettingsTile(
              title: 'Export data (Coming Soon)',
              subtitle: 'Download your personal history.',
              icon: Icons.file_upload_rounded,
              onTap: () {},
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(
    BuildContext context, {
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onTap,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  options[index],
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.onPrimary
                        : AppColors.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  int _getThemeIndex(ThemeMode mode) {
    if (mode == ThemeMode.light) return 0;
    if (mode == ThemeMode.dark) return 1;
    return 2;
  }

  int _getSizeIndex(String size) {
    if (size == 'Small') return 0;
    if (size == 'Medium') return 1;
    return 2;
  }

  void _showLanguageDialog(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text(
            "Select Language",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                context,
                "English",
                const Locale('en'),
                languageProvider,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String name,
    Locale locale,
    LanguageProvider languageProvider,
  ) {
    final isSelected =
        languageProvider.locale.languageCode == locale.languageCode;

    return ListTile(
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.onSurface,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        languageProvider.setLocale(locale);
        Navigator.pop(context);
      },
    );
  }
}
