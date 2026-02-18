class AppConstants {
  AppConstants._();

  static const String baseUrl = 'https://attendance-yagn.onrender.com';
  static const String wsUrl =
      'wss://attendance-yagn.onrender.com/ws/transactions';
  static const String appName = 'Attendance Dashboard';

  // SharedPreferences keys
  static const String keyUsername = 'username';
  static const String keyPassword = 'password';
  static const String keyUserID = 'userID';
  static const String keyIsAdmin = 'isAdmin';
  static const String keyThemeMode = 'themeMode';
  static const String keyLocale = 'locale';
}
