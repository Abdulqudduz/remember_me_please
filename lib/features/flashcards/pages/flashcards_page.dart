import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';
import 'package:remember_me_please/features/flashcards/providers/flashcard_provider.dart';
import 'package:remember_me_please/features/flashcards/widgets/flashcard_view.dart';

class FlashcardsPage extends StatelessWidget {
  const FlashcardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FlashcardsPageContent();
  }
}

class FlashcardsPageContent extends StatefulWidget {
  const FlashcardsPageContent({super.key});

  @override
  State<FlashcardsPageContent> createState() => _FlashcardsPageContentState();
}

class _FlashcardsPageContentState extends State<FlashcardsPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),

          // TAB BAR (FIXED VISIBILITY)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 56,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: AppColors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                labelColor: AppColors.onPrimary,
                unselectedLabelColor: AppColors.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'People'),
                  Tab(text: 'Reminders'),
                  Tab(text: 'Moments'),
                ],
              ),
            ),
          ),

          // const SizedBox(height: 3),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildView('People'),
                _buildReminderView(),
                _buildView('Moments'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [],
    );
  }

  void _navigateToReminderDetail(String title, String date, String detail) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: AppColors.transparent,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 16),
                Text(detail, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildView(String category) {
    return Consumer<FlashcardProvider>(
      builder: (context, provider, child) {
        final state = provider.getCategoryState(category);

        if (state.cards.isEmpty) {
          return const Center(
            child: Text("No cards available in this category."),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        height: 420,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            final offsetAnimation = Tween<Offset>(
                              begin: Offset(state.isNext ? 1 : -1, 0),
                              end: Offset.zero,
                            ).animate(animation);

                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                          child: FlashcardView(
                            onIwasRight: () => context
                                .read<FlashcardProvider>()
                                .previousCard(category),
                            onIwasWrong: () => context
                                .read<FlashcardProvider>()
                                .nextCard(category),
                            key: ValueKey('${category}_${state.currentIndex}'),
                            category: category,
                            card: state.cards[state.currentIndex],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // _buildActionArea(context, category),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
