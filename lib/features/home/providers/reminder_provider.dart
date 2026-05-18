import 'package:flutter/material.dart';
import '../../../data/models/reminder_model.dart';
import '../../../data/sources/local/objectbox_service.dart';

class ReminderProvider with ChangeNotifier {
  List<ReminderModel> _reminders = [];
  final ObjectBoxService _objectBoxService = ObjectBoxService();

  ReminderProvider() {
    _loadReminders();
  }

  void _loadReminders() {
    _reminders = _objectBoxService.getReminders();
    notifyListeners();
  }

  List<ReminderModel> get activeReminders =>
      _reminders.where((r) => !r.isCompleted).toList();

  void completeReminder(int id) {
    final reminder = _objectBoxService.getReminderById(id);
    if (reminder != null) {
      reminder.isCompleted = true;
      _objectBoxService.updateReminder(reminder);
      _loadReminders();
    }
  }
}