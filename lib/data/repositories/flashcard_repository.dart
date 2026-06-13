import 'package:remember_me_please/core/models/flashcard_model.dart';
import 'package:remember_me_please/data/sources/local/objectbox_service.dart';

class FlashcardRepository {
  FlashcardRepository({required this.objectBoxService});

  final ObjectBoxService objectBoxService;

  List<FlashcardModel> fetchAllFlashcards() {
    return objectBoxService.getFlashcards();
  }

  FlashcardModel? fetchFlashcardById(int id) {
    return objectBoxService.getFlashcardById(id);
  }

  int addNewFlashcard(FlashcardModel flashcard) {
    return objectBoxService.addFlashcard(flashcard);
  }

  bool deleteFlashcardById(int id) {
    return objectBoxService.deleteFlashcard(id);
  }
}
