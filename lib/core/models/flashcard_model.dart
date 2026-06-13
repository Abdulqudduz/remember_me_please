import 'package:objectbox/objectbox.dart';

/// Categories for flashcards — replaces the old MemoryCardCategory enum
/// from core/models/memory_card.dart.
enum FlashcardCategory { person, reminder, moment }

@Entity()
class FlashcardModel {
  int id;
  final String question;
  final String title;
  final String? subtitle;
  final String? frontCardImage;
  final String? moreDetails;

  /// Persisted as the enum index (0 = person, 1 = reminder, 2 = moment).
  int categoryIndex;

  @Transient()
  FlashcardCategory get category => FlashcardCategory.values[categoryIndex];
  set category(FlashcardCategory value) => categoryIndex = value.index;

  /// Milliseconds since epoch — ObjectBox doesn't natively store DateTime.
  int createdAt;

  FlashcardModel({
    this.id = 0,
    required this.question,
    required this.title,
    this.subtitle,
    this.frontCardImage,
    this.moreDetails,
    this.categoryIndex = 0,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  FlashcardModel copyWith({
    int? id,
    String? question,
    String? title,
    String? subtitle,
    String? frontImage,
    String? backText,
    int? categoryIndex,
    int? createdAt,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      question: question ?? this.question,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      frontCardImage: frontImage ?? this.frontCardImage,
      moreDetails: backText ?? this.moreDetails,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
