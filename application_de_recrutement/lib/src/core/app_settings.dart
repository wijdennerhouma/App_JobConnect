import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  french('fr', 'Français'),
  english('en', 'English'),
  arabic('ar', 'العربية');

  const AppLanguage(this.code, this.name);
  final String code;
  final String name;
}

enum AppThemeMode {
  system,
  light,
  dark;

  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'Système';
      case AppThemeMode.light:
        return 'Clair';
      case AppThemeMode.dark:
        return 'Sombre';
    }
  }

  ThemeMode toFlutterThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

class AppSettings extends ChangeNotifier {
  AppLanguage _language = AppLanguage.french;
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  AppLanguage get language => _language;
  AppThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get emailNotifications => _emailNotifications;
  bool get pushNotifications => _pushNotifications;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger la langue
    final langCode = prefs.getString('app_language') ?? 'fr';
    _language = AppLanguage.values.firstWhere(
      (lang) => lang.code == langCode,
      orElse: () => AppLanguage.french,
    );

    // Charger le thème
    final themeModeStr = prefs.getString('theme_mode') ?? 'system';
    _themeMode = AppThemeMode.values.firstWhere(
      (mode) => mode.name == themeModeStr,
      orElse: () => AppThemeMode.system,
    );

    // Charger les paramètres de notifications
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _emailNotifications = prefs.getBool('email_notifications') ?? true;
    _pushNotifications = prefs.getBool('push_notifications') ?? true;

    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language.code);
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    notifyListeners();
  }

  Future<void> setEmailNotifications(bool enabled) async {
    _emailNotifications = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_notifications', enabled);
    notifyListeners();
  }

  Future<void> setPushNotifications(bool enabled) async {
    _pushNotifications = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', enabled);
    notifyListeners();
  }
}
