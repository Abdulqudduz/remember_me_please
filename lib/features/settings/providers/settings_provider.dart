import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  bool _listenContinuously = true;
  bool _tapToRead = true;
  bool _aiReminders = true;
  bool _locationSuggestions = false;
  String _textSize = 'Medium';
  bool _highContrast = false;

  bool get listenContinuously => _listenContinuously;
  bool get tapToRead => _tapToRead;
  bool get aiReminders => _aiReminders;
  bool get locationSuggestions => _locationSuggestions;
  String get textSize => _textSize;
  bool get highContrast => _highContrast;



  void toggleTapToRead(bool value) {
    _tapToRead = value;
    notifyListeners();
  }

  void toggleAiReminders(bool value) {
    _aiReminders = value;
    notifyListeners();
  }

  void toggleLocationSuggestions(bool value) {
    _locationSuggestions = value;
    notifyListeners();
  }

  void setTextSize(String size) {
    _textSize = size;
    notifyListeners();
  }

  void toggleHighContrast(bool value) {
    _highContrast = value;
    notifyListeners();
  }
}
