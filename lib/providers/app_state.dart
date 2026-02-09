import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLocale(String languageCode) {
    _locale = Locale(languageCode);
    notifyListeners();
  }

  bool get isRTL => _locale.languageCode == 'ar';

  String currentUserName = '';
  String currentUserEmail = '';
  String currentUserRole = '';
  String currentUserSpecialty = '';

  void setCurrentUser(
      String name, String email, String role, String specialty) {
    currentUserName = name;
    currentUserEmail = email;
    currentUserRole = role;
    currentUserSpecialty = specialty;
    notifyListeners();
  }

  String? _userRole;
  String? get userRole => _userRole;
  void setUserRole(String? role) {
    _userRole = role;
    notifyListeners();
  }

  // Fake data
  Map<String, String> currentUserStats = {
    'tasksCompleted': '0/0',
    'attendance': '0%',
    'daysLeft': '0',
  };

  List<Map<String, String>> currentUserTasks = [
    {
      'title': 'Feature Implementation',
      'priority': 'High',
      'status': 'Pending'
    },
    {'title': 'Bug Fixing', 'priority': 'Medium', 'status': 'Completed'},
    {'title': 'Documentation', 'priority': 'Low', 'status': 'In Progress'},
  ];

  List<Map<String, String>> currentUserNotifications = [
    {'title': 'Task assigned', 'time': '2 hours ago'},
    {'title': 'Report approved', 'time': '5 hours ago'},
    {'title': 'Meeting scheduled', 'time': 'Yesterday'},
  ];

  // Translation
  String translate(String key) {
    final translations = {
      'en': {
        'welcome': 'Welcome',
        'tasks_completed': 'Tasks Completed',
        'attendance': 'Attendance',
        'days_left': 'Days Left'
      },
      'fr': {
        'welcome': 'Bienvenue',
        'tasks_completed': 'Tâches terminées',
        'attendance': 'Présence',
        'days_left': 'Jours restants'
      },
      'ar': {
        'welcome': 'مرحباً',
        'tasks_completed': 'المهام المكتملة',
        'attendance': 'الحضور',
        'days_left': 'الأيام المتبقية'
      },
    };
    return translations[_locale.languageCode]?[key] ?? key;
  }
}
