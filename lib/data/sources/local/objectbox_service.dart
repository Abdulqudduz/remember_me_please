import 'package:flutter/foundation.dart';
import 'package:remember_me_please/data/models/conversation_model.dart';
import 'package:remember_me_please/data/models/person_model.dart';
import 'package:remember_me_please/data/models/reminder_model.dart';
import 'package:remember_me_please/main.dart';
import 'package:remember_me_please/objectbox.g.dart';

class ObjectBoxService {
  late final Box<PersonModel>? _personBox;

  late final Box<ConversationModel>? _conversationBox;
  late final Box<ReminderModel>? _reminderBox;

  ObjectBoxService() {
    final store = objectBox?.store;

    if (store == null) {
      debugPrint("WARNING: ObjectBox store is not initialized. Running database service in stub mode.");
      _personBox = null;

      _conversationBox = null;
      _reminderBox = null;
      return;
    }

    _personBox = store.box<PersonModel>();
    _conversationBox = store.box<ConversationModel>();
    _reminderBox = store.box<ReminderModel>();
  }

  // Person CRUD

  int addPerson(PersonModel person) {
    if (_personBox == null) {
      debugPrint("Stub Mode: Successfully simulated adding person.");
      return 1;
    }
    try {
      return _personBox.put(person);
    } on ObjectBoxException catch (e) {
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('full') || errorMessage.contains('no space')) {
        debugPrint(
          "CRITICAL: Device storage is full. User needs to clear space.",
        );
        return -1;
      }

      debugPrint("ObjectBox Database Error: $e");
      return 0;
    } catch (e) {
      debugPrint("Unknown Error saving person: $e");
      return 0;
    }
  }

  List<PersonModel> getPeople() {
    if (_personBox == null) {
      return [];
    }
    return _personBox.getAll();
  }

  bool deletePerson(int id) {
    if (_personBox == null) {
      return true;
    }
    return _personBox.remove(id);
  }

  // Vector search for live camera

  PersonModel? findMatchingPerson(Float32List targetEmbedding) {
    if (_personBox == null) {
      return null;
    }
    try {
      final query = _personBox
          .query(
            PersonModel_.faceEmbedding.nearestNeighborsF32(targetEmbedding, 1),
          )
          .build();

      final results = query.findWithScores();
      query.close();

      if (results.isNotEmpty) {
        final bestMatch = results.first;
        final person = bestMatch.object;
        final distanceScore = bestMatch.score;

        debugPrint("AI Match Score for ${person.name}: $distanceScore");

        if (distanceScore < 1.1) {
          return person;
        } else {
          debugPrint(
            "Stranger detected. Closest match ($distanceScore) was too far away.",
          );
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error searching for face in ObjectBox: $e");
      return null;
    }
  }

  // Conversation CRUD

  int addConversation(ConversationModel conversation) {
    if (_conversationBox == null) {
      debugPrint("Stub Mode: Successfully simulated adding conversation.");
      return 1;
    }
    try {
      return _conversationBox.put(conversation);
    } on ObjectBoxException catch (e) {
      debugPrint("ObjectBox Error saving conversation: $e");
      return 0;
    } catch (e) {
      debugPrint("Unknown Error saving conversation: $e");
      return 0;
    }
  }

  List<ConversationModel> getConversations() {
    if (_conversationBox == null) {
      return [];
    }
    return _conversationBox.getAll();
  }

  ConversationModel? getConversationById(int id) {
    if (_conversationBox == null) {
      return null;
    }
    return _conversationBox.get(id);
  }

  bool deleteConversation(int id) {
    if (_conversationBox == null) {
      return true;
    }
    return _conversationBox.remove(id);
  }

  // Reminder CRUD

  int addReminder(ReminderModel reminder) {
    if (_reminderBox == null) {
      debugPrint("Stub Mode: Successfully simulated adding reminder.");
      return 1;
    }
    try {
      return _reminderBox.put(reminder);
    } on ObjectBoxException catch (e) {
      debugPrint("ObjectBox Error saving reminder: $e");
      return 0;
    } catch (e) {
      debugPrint("Unknown Error saving reminder: $e");
      return 0;
    }
  }

  List<ReminderModel> getReminders() {
    if (_reminderBox == null) {
      return [];
    }
    return _reminderBox.getAll();
  }

  ReminderModel? getReminderById(int id) {
    if (_reminderBox == null) {
      return null;
    }
    return _reminderBox.get(id);
  }

  int updateReminder(ReminderModel reminder) {
    if (_reminderBox == null) {
      debugPrint("Stub Mode: Successfully simulated updating reminder.");
      return 1;
    }
    try {
      return _reminderBox.put(reminder);
    } on ObjectBoxException catch (e) {
      debugPrint("ObjectBox Error updating reminder: $e");
      return 0;
    } catch (e) {
      debugPrint("Unknown Error updating reminder: $e");
      return 0;
    }
  }

  bool deleteReminder(int id) {
    if (_reminderBox == null) {
      return true;
    }
    return _reminderBox.remove(id);
  }

  /// Returns a live stream of all conversations, sorted by newest first.
  Stream<List<ConversationModel>> watchConversations() {
    if (_conversationBox == null) {
      return Stream.value(<ConversationModel>[]);
    }
    return _conversationBox
        .query()
        .order(ConversationModel_.createdAt, flags: Order.descending)
        .watch(triggerImmediately: true)
        .map((query) => query.find());
  }

  /// Retrieves a plain-text context block for the RAG pipeline.
  String retrieveContextForQuery(String query) {
    if (_conversationBox == null || _reminderBox == null) {
      return 'No relevant memory data was found for this query.';
    }
    final buffer = StringBuffer();
    final lowerQuery = query.toLowerCase();

    final conversations = _conversationBox.getAll();

    final keywords = lowerQuery.split(' ').where((w) => w.length > 2).toList();

    final relevantConversations = conversations.where((c) {
      final searchTarget =
          '${c.shortTitle} ${c.summary} ${c.personName}'.toLowerCase();
      return keywords.any((kw) => searchTarget.contains(kw));
    }).toList();

    if (relevantConversations.isNotEmpty) {
      buffer.writeln('--- RECENT CONVERSATIONS ---');
      for (final conv in relevantConversations.take(3)) {
        buffer.writeln('Person: ${conv.personName}');
        buffer.writeln('Summary: ${conv.summary}');
        if (conv.importantDetails.isNotEmpty) {
          buffer.writeln('Details: ${conv.importantDetails.join('; ')}');
        }
        buffer.writeln();
      }
    }

    final activeReminders = _reminderBox
        .getAll()
        .where((r) => !r.isCompleted)
        .toList();

    if (activeReminders.isNotEmpty) {
      buffer.writeln('--- PENDING REMINDERS ---');
      for (final reminder in activeReminders) {
        buffer.writeln('- ${reminder.title} at ${reminder.time}');
      }
      buffer.writeln();
    }

    if (buffer.isEmpty) {
      return 'No relevant memory data was found for this query.';
    }

    return buffer.toString().trim();
  }
}
