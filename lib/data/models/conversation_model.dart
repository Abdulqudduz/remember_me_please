// data/models/conversation_model.dart
import 'package:objectbox/objectbox.dart';

// Sentinel constant used in copyWith to distinguish between "not provided"
// and an intentional null assignment for nullable fields.
const Object _sentinel = Object();

@Entity()
class ConversationModel {
  @Id()
  int id;

  String shortTitle;
  String personName;
  String timeLabel;
  String summary;

  // Consistently use personImagePath across the codebase
  String? personImagePath;

  List<String> importantDetails;
  List<String> actionsItems;

  String conversationAudioFilePathUrl;
  String transcriptJson;

  // Path to the TTS-generated WAV file for reading the summary aloud.
  // Null until the pipeline generates and saves the audio file.
  String? summaryAudioPath;

  String tagsString;

  @Transient()
  List<String> get tags => tagsString.isEmpty
      ? []
      : tagsString.split(',').map((t) => t.trim()).toList();
  set tags(List<String> value) => tagsString = value.join(',');

  int createdAt;

  ConversationModel({
    this.id = 0,
    this.shortTitle = 'New Conversation',
    required this.personName,
    required this.timeLabel,
    required this.summary,
    this.personImagePath,
    this.importantDetails = const [],
    this.actionsItems = const [],
    this.conversationAudioFilePathUrl = '',
    this.transcriptJson = '',
    // Path to the locally generated TTS audio file; null until audio is ready
    this.summaryAudioPath,
    this.tagsString = '',
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  /// Returns a copy of this model with the specified fields overridden.
  ///
  /// For the nullable [summaryAudioPath] field, pass the sentinel constant
  /// [_sentinel] (the default) to preserve the current value, or pass an
  /// explicit String? to override it (including null).
  ConversationModel copyWith({
    int? id,
    String? shortTitle,
    String? personName,
    String? timeLabel,
    String? summary,
    String? personImagePath,
    List<String>? importantDetails,
    List<String>? actionsItems,
    String? conversationAudioFilePathUrl,
    String? transcriptJson,
    // Sentinel default distinguishes "caller did not provide this" from null
    Object? summaryAudioPath = _sentinel,
    String? tagsString,
    int? createdAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      shortTitle: shortTitle ?? this.shortTitle,
      personName: personName ?? this.personName,
      timeLabel: timeLabel ?? this.timeLabel,
      summary: summary ?? this.summary,
      personImagePath: personImagePath ?? this.personImagePath,
      importantDetails: importantDetails ?? this.importantDetails,
      actionsItems: actionsItems ?? this.actionsItems,
      conversationAudioFilePathUrl:
          conversationAudioFilePathUrl ?? this.conversationAudioFilePathUrl,
      transcriptJson: transcriptJson ?? this.transcriptJson,
      // If the caller passed nothing, keep the existing path; otherwise use theirs
      summaryAudioPath: summaryAudioPath == _sentinel
          ? this.summaryAudioPath
          : summaryAudioPath as String?,
      tagsString: tagsString ?? this.tagsString,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
