import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/navigation_provider.dart';
import '../../home/pages/home_page.dart';
import '../../conversations/pages/conversations_page.dart';
import '../../people/pages/people_page.dart';
import '../../settings/pages/settings_page.dart';
import '../../../core/widgets/ai_assistant_modal.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../people/pages/add_person_page.dart';

class MainNavigationPage extends StatelessWidget {
  MainNavigationPage({super.key});

  final List<Widget> _pages = const [
    HomePageContent(),
    ConversationsPage(),
    PeoplePageContent(),
  ];

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Today';
      case 1:
        return 'Your Conversations';
      case 2:
        return 'People You Know';
      default:
        return 'Mindful Sanctuary';
    }
  }

  Widget? _buildFAB(BuildContext context, int index) {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.primary,
      onPressed: () => showAIAssistantModal(context),
      icon: const CircleAvatar(
        child: Icon(Icons.mic, color: AppColors.onPrimary),
      ),
      label: const Text(
        'AI Assistant',
        style: TextStyle(
          color: AppColors.onPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
        centerTitle: navProvider.currentIndex != 1,
        forceMaterialTransparency: true,
        title: Text(
          _getTitle(navProvider.currentIndex),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: AppColors.primary,
              size: 28,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: navProvider.currentIndex, children: _pages),
      floatingActionButton: _buildFAB(context, navProvider.currentIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.06),
              blurRadius: 32,
              offset: const Offset(0, -12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SizedBox(
            height: 120,
            child: BottomNavigationBar(
              currentIndex: navProvider.currentIndex,
              onTap: (index) => navProvider.setIndex(index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.scaffoldBackground,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.onSurfaceVariant,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 28),
                  activeIcon: Icon(Icons.home, size: 28),
                  label: 'HOME',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline, size: 28),
                  activeIcon: Icon(Icons.chat_bubble, size: 28),
                  label: 'CONVERSATIONS',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_outlined, size: 28),
                  activeIcon: Icon(Icons.group, size: 28),
                  label: 'PEOPLE',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
