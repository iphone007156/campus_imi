import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Слушаем изменения, чтобы экран перерисовывался при смене темы/языка
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final langCode = SettingsService.instance.locale.languageCode;
        final t = (String key) => AppStrings.t(key, langCode);
        final themeMode = SettingsService.instance.themeMode;

        return Scaffold(
          appBar: AppBar(title: Text(t('settings'))),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.brightness_6),
                      title: Text(t('theme')),
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(t('theme_system')),
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      onChanged: (val) =>
                          SettingsService.instance.setTheme(val!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(t('theme_light')),
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (val) =>
                          SettingsService.instance.setTheme(val!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(t('theme_dark')),
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (val) =>
                          SettingsService.instance.setTheme(val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(t('language')),
                    ),
                    RadioListTile<String>(
                      title: const Text('Русский'),
                      value: 'ru',
                      groupValue: langCode,
                      onChanged: (val) =>
                          SettingsService.instance.setLanguage(val!),
                    ),
                    RadioListTile<String>(
                      title: const Text('English'),
                      value: 'en',
                      groupValue: langCode,
                      onChanged: (val) =>
                          SettingsService.instance.setLanguage(val!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}