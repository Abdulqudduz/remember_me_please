import 'package:flutter/material.dart';

class HomeProvider extends ChangeNotifier {
  String get greeting {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get formattedDate {
    // Use the intl package or manual formatting
    return "Saturday, 28 April";
  }
}
