import 'package:flutter/foundation.dart';
// core/services/active_person_tracker.dart

class ActivePersonTracker {
  static final ActivePersonTracker _instance = ActivePersonTracker._internal();
  factory ActivePersonTracker() => _instance;
  ActivePersonTracker._internal();

  String? _recentPersonName;
  String? _recentPersonImagePath;
  DateTime? _lastSeenTime;

  // Call this right after your camera matches a face!
  void registerFaceMatch(String personName, String imagePath) {
    _recentPersonName = personName;
    _recentPersonImagePath = imagePath;
    _lastSeenTime = DateTime.now();
  }

  // Returns [Name, ImagePath] if seen within 2 minutes
  Map<String, String?> getActivePerson() {
    if (_recentPersonName == null || _lastSeenTime == null) {
      debugPrint(' No recent ACTIVE PERSON found.');
      return {'name': 'Unknown', 'image': null};
    }

    if (DateTime.now().difference(_lastSeenTime!).inSeconds <= 600) {
      final data = {
        'name': _recentPersonName!,
        'image': _recentPersonImagePath,
      };
      debugPrint(' Recent ACTIVE PERSON FOUND NAME: $_recentPersonName.');
      _recentPersonName = null; // Clear it so it doesn't leak to future chats
      return data;
    }
    debugPrint(' Recent ACTIVE PERSON FOUND NAME: $_recentPersonName.');
    return {'name': 'Unknown', 'image': null};
  }
}
