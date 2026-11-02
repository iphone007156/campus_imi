import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final enabled = SettingsService.instance.notificationsEnabled;

        return Scaffold(
          appBar: AppBar(title: const Text('Уведомления')),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    SwitchListTile(
                      value: enabled,
                      title: const Text('Все уведомления'),
                      subtitle: const Text(
                        'Напоминания о парах, новости, мероприятия',
                        style: TextStyle(fontSize: 12),
                      ),
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (v) async {
                        // 1. Сохраняем флаг
                        SettingsService.instance
                            .setNotificationsEnabled(v);

                        // 2. Отменяем локальные уведомления при выключении
                        if (!v) {
                          await NotificationService.cancelAll();
                        }

                        // 3. Подписка/отписка OneSignal (актуальный API v5+)
                        try {
                          if (!v) {
                            OneSignal.User.pushSubscription.optOut();
                          } else {
                            OneSignal.User.pushSubscription.optIn();
                          }
                        } catch (e) {
                          debugPrint('📨 [PUSH] Ошибка OneSignal: $e');
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(v
                                  ? '✅ Уведомления включены'
                                  : '🔕 Уведомления отключены'),
                              backgroundColor: v ? Colors.green : Colors.orange,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (enabled)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.accentBlue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Сейчас вы получаете напоминания о парах и уведомления о новостях и мероприятиях.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!enabled)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications_off, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Уведомления отключены. Вы не будете получать напоминания о парах, новости и события.',
                          style: TextStyle(fontSize: 12),
                        ),
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