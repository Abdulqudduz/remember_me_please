import 'package:remember_me_please/data/models/reminder_model.dart';
import 'package:remember_me_please/data/sources/local/objectbox_service.dart';

class ReminderRepository {
  ReminderRepository({required this.objectBoxService});

  final ObjectBoxService objectBoxService;

  List<ReminderModel> fetchAllReminders() {
    return objectBoxService.getReminders();
  }

  ReminderModel? fetchReminderById(int id) {
    return objectBoxService.getReminderById(id);
  }

  int addNewReminder(ReminderModel reminder) {
    return objectBoxService.addReminder(reminder);
  }

  int updateReminder(ReminderModel reminder) {
    return objectBoxService.updateReminder(reminder);
  }

  bool deleteReminderById(int id) {
    return objectBoxService.deleteReminder(id);
  }
}
