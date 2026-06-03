import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';
import 'package:remember_me_please/core/widgets/ai_assistant_modal.dart';
import 'package:remember_me_please/core/widgets/app_scaffold.dart';
import 'package:remember_me_please/features/conversations/pages/conversations_page.dart';
import 'package:remember_me_please/features/flashcards/pages/create_memory_card_page.dart';
import 'package:remember_me_please/features/flashcards/pages/flashcards_page.dart';
import 'package:remember_me_please/features/home/pages/home_page.dart';
import 'package:remember_me_please/features/navigation/providers/navigation_provider.dart';
import 'package:remember_me_please/features/people/pages/people_page.dart';
import 'package:remember_me_please/features/settings/pages/settings_page.dart';

class MainNavigationPage extends StatelessWidget {
  const MainNavigationPage({super.key});

  final List<Widget> _pages = const [
    HomePageContent(),
    ConversationsPage(),
    PeoplePageContent(),
    FlashcardsPage(),
  ];

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Today';
      case 1:
        return 'Your Conversations';
      case 2:
        return 'People You Know';
      case 3:
        return 'Flashcards';
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
        leading:
            (navProvider.currentIndex == 2 || navProvider.currentIndex == 3)
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Center(
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryContainer.withValues(
                      alpha: 0.2,
                    ),
                    child: IconButton(
                      icon: Icon(
                        navProvider.currentIndex == 2
                            ? Icons.search
                            : Icons.add,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      onPressed: () {
                        if (navProvider.currentIndex == 2) {
                          // search person
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CreateMemoryCardPage(),
                            ),
                          );
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              )
            : null,
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
                BottomNavigationBarItem(
                  icon: Icon(Icons.style_outlined, size: 28),
                  activeIcon: Icon(Icons.style, size: 28),
                  label: 'FLASHCARDS',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
