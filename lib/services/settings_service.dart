import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._();
  SettingsService._();

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ru');
  bool _notificationsEnabled = true;
  bool _privacyAccepted = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get privacyAccepted => _privacyAccepted;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString('theme_mode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
          (e) => e.name == themeStr,
      orElse: () => ThemeMode.system,
    );

    final langStr = prefs.getString('language') ?? 'ru';
    _locale = Locale(langStr);

    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _privacyAccepted = prefs.getBool('privacy_accepted') ?? false;

    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _saveThemeToDisk(mode);
  }

  void setLanguage(String langCode) {
    if (_locale.languageCode == langCode) return;
    _locale = Locale(langCode);
    notifyListeners();
    _saveLangToDisk(langCode);
  }

  void setNotificationsEnabled(bool enabled) {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();
    _saveNotificationsToDisk(enabled);
  }

  Future<void> setPrivacyAccepted(bool value) async {
    if (_privacyAccepted == value) return;
    _privacyAccepted = value;
    notifyListeners();
    await _savePrivacyToDisk(value);
  }

  Future<void> _saveThemeToDisk(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', mode.name);
    } catch (_) {}
  }

  Future<void> _saveLangToDisk(String langCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', langCode);
    } catch (_) {}
  }

  Future<void> _saveNotificationsToDisk(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);
    } catch (_) {}
  }

  Future<void> _savePrivacyToDisk(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_accepted', value);
    } catch (_) {}
  }
}