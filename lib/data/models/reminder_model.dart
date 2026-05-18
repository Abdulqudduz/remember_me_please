import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';

// Enum that defines all available reminder icons in a type-safe way
enum ReminderIcon { alarm, medication, home, fitness, water, notification }

// Converts ReminderIcon enum to and from an int for ObjectBox storage
class ReminderIconConverter {
  static int toInt(ReminderIcon icon) => icon.index;

  static ReminderIcon fromInt(int value) => ReminderIcon.values[value];
}

// ObjectBox entity representing a reminder stored in the database
@Entity()
class ReminderModel {
  int id;

  final String title;
  final String time;

  // Stores icon as enum index instead of IconData
  final int iconIndex;

  final int brandColorValue;
  final int containerColorValue;
  final int onContainerColorValue;

  bool isCompleted;

  int createdAt;

  ReminderModel({
    this.id = 0,
    required this.title,
    required this.time,
    required this.iconIndex,
    required this.brandColorValue,
    required this.containerColorValue,
    required this.onContainerColorValue,
    this.isCompleted = false,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  // Creates a modified copy of this ReminderModel instance
  ReminderModel copyWith({
    int? id,
    String? title,
    String? time,
    int? iconIndex,
    int? brandColorValue,
    int? containerColorValue,
    int? onContainerColorValue,
    bool? isCompleted,
    int? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      iconIndex: iconIndex ?? this.iconIndex,
      brandColorValue: brandColorValue ?? this.brandColorValue,
      containerColorValue: containerColorValue ?? this.containerColorValue,
      onContainerColorValue:
          onContainerColorValue ?? this.onContainerColorValue,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// UI helper extension to convert stored values into usable Flutter types
extension ReminderModelUI on ReminderModel {
  // Converts stored index back to enum
  ReminderIcon get iconType => ReminderIconConverter.fromInt(iconIndex);

  // Maps enum to actual Flutter Icons (avoids dynamic IconData creation)
  IconData get icon {
    switch (iconType) {
      case ReminderIcon.alarm:
        return Icons.alarm;
      case ReminderIcon.medication:
        return Icons.medication;
      case ReminderIcon.home:
        return Icons.home;
      case ReminderIcon.fitness:
        return Icons.fitness_center;
      case ReminderIcon.water:
        return Icons.water_drop;
      case ReminderIcon.notification:
        return Icons.notifications;
    }
  }

  // Converts stored int values back to Color objects
  Color get brandColor => Color(brandColorValue);

  Color get containerColor => Color(containerColorValue);

  Color get onContainerColor => Color(onContainerColorValue);
}
