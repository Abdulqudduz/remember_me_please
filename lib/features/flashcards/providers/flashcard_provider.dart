import 'package:flutter/foundation.dart';
import 'package:remember_me_please/core/models/flashcard_model.dart';
import 'package:remember_me_please/data/repositories/flashcard_repository.dart';

/// Represents the state of a specific category of flashcards
class FlashcardCategoryState {
  final List<FlashcardModel> cards;
  int currentIndex;
  bool isNext;
  bool isRevealed;

  FlashcardCategoryState({
    required this.cards,
    this.currentIndex = 0,
    this.isNext = true,
    this.isRevealed = false,
  });
}

class FlashcardProvider extends ChangeNotifier {
  final FlashcardRepository flashcardRepository;

  // Declare the missing _categories map
  Map<String, FlashcardCategoryState> _categories = {};

  FlashcardProvider({required this.flashcardRepository}) {
    _loadFlashcards();
  }

  void _loadFlashcards() {
    // Use the injected repository instead of _objectBoxService
    final allFlashcards = flashcardRepository.fetchAllFlashcards();

    _categories = {
      'People': FlashcardCategoryState(
        cards: allFlashcards
            .where((f) => f.category == FlashcardCategory.person)
            .toList(),
      ),
      'Reminder': FlashcardCategoryState(
        cards: allFlashcards
            .where((f) => f.category == FlashcardCategory.reminder)
            .toList(),
      ),
      'Moments': FlashcardCategoryState(
        cards: allFlashcards
            .where((f) => f.category == FlashcardCategory.moment)
            .toList(),
      ),
    };
    notifyListeners();
    print(_categories);
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
    if (!state.isRevealed) {
      state.isRevealed = true;
      notifyListeners();
    }
  }

  void addFlashcard(FlashcardModel flashcard) {
    flashcardRepository.addNewFlashcard(flashcard);
    _loadFlashcards(); // Refresh the state after adding
  }

  void deleteFlashcard(int id) {
    flashcardRepository.deleteFlashcardById(id);
    _loadFlashcards(); // Refresh the state after deletion
  }
}
