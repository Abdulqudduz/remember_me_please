import 'package:flutter/foundation.dart';
import 'package:remember_me_please/data/models/flashcard_model.dart';
import 'package:remember_me_please/data/sources/local/objectbox_service.dart';


class FlashcardCategoryState {
  int currentIndex = 0;
  bool isNext = true;
  bool isRevealed = false;
  final List<FlashcardModel> cards;

  FlashcardCategoryState({required this.cards});
}

class FlashcardProvider extends ChangeNotifier {
  final ObjectBoxService _objectBoxService = ObjectBoxService();
  Map<String, FlashcardCategoryState> _categories = {};

  FlashcardProvider() {
    _loadFlashcards();
  }

  void _loadFlashcards() {
    final allFlashcards = _objectBoxService.getFlashcards();
    _categories = {
      'People': FlashcardCategoryState(
        cards: allFlashcards
            .where((f) => f.category == FlashcardCategory.person)
            .toList(),
      ),
      'Moments': FlashcardCategoryState(
        cards: allFlashcards
            .where((f) => f.category == FlashcardCategory.moment)
            .toList(),
      ),
    };
    notifyListeners();
  }

  FlashcardCategoryState getCategoryState(String category) {
    return _categories[category] ?? FlashcardCategoryState(cards: []);
  }

  void nextCard(String category) {
    final state = getCategoryState(category);
    if (state.cards.isNotEmpty && state.currentIndex < state.cards.length - 1) {
      state.currentIndex++;
      state.isNext = true;
      state.isRevealed = false;
      notifyListeners();
    }
  }

  void previousCard(String category) {
    final state = getCategoryState(category);
    if (state.cards.isNotEmpty && state.currentIndex > 0) {
      state.currentIndex--;
      state.isNext = false;
      state.isRevealed = false;
      notifyListeners();
    }
  }

  void revealCard(String category) {
    final state = getCategoryState(category);
    state.isRevealed = true;
    notifyListeners();
  }
}
