import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'settings_service.dart';

/// Одно напоминание о конкретной паре (с датой и временем начала).
class LessonReminder {
  final String key;
  final String subject;
  final String room;
  final String time;
  final DateTime start;
  const LessonReminder({
    required this.key,
    required this.subject,
    required this.room,
    required this.time,
    required this.start,
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo));

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localPlugin.initialize(initSettings);

    // ✅ Запрос разрешений для iOS (критично!)
    final iosPlugin = _localPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // ✅ Запрос разрешений на уведомления (Android 13+)
    final androidPlugin = _localPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    // ✅ Запрос разрешения на точные будильники (Android 12+)
    if (androidPlugin != null) {
      final canScheduleExact =
      await androidPlugin.canScheduleExactNotifications();
      if (canScheduleExact != true) {
        await androidPlugin.requestExactAlarmsPermission();
      }
    }

    // ✅ Привязка OneSignal к Firebase Auth
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        OneSignal.login(user.uid);
      } else {
        OneSignal.logout();
      }
    });
  }

  static Future<void> cancelAll() async {
    await _localPlugin.cancelAll();
    debugPrint('🔔 [NOTIF] Все локальные уведомления отменены');
  }

  static Future<void> scheduleLessonReminders(List<dynamic> lessons) async {
    if (!SettingsService.instance.notificationsEnabled) {
      debugPrint('🔔 [NOTIF] Уведомления отключены, пропускаем');
      return;
    }

    if (lessons.isEmpty) {
      debugPrint('🔔 [NOTIF] Нет пар для планирования');
      return;
    }

    await _localPlugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    int scheduled = 0;

    // ✅ Проверяем, разрешены ли точные будильники (для Android 14)
    bool canScheduleExact = false;
    final androidPlugin = _localPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      canScheduleExact =
          await androidPlugin.canScheduleExactNotifications() ?? false;
    }

    for (final lesson in lessons) {
      try {
        final dayIndex = (lesson.dayIndex as int?) ?? 0;

        final rawTime = (lesson.time as String?) ?? '';
        final timeStr = rawTime
            .split('-')
            .first
            .trim()
            .replaceAll('.', ':');
        final timeParts = timeStr.split(':');
        if (timeParts.length != 2) {
          debugPrint('🔔 [NOTIF] Неверный формат времени: "$rawTime"');
          continue;
        }

        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        if (hour == 0 && minute == 0) {
          debugPrint('🔔 [NOTIF] Неверное время: "$rawTime"');
          continue;
        }

        final targetDate = _nextDateForWeekday(now, dayIndex);
        final lessonStart = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
          minute,
        );

        final reminderTime = lessonStart.subtract(const Duration(minutes: 10));

        if (reminderTime.isBefore(now)) {
          debugPrint('🔔 [NOTIF] Пропущено (время прошло): ${lesson.subject}');
          continue;
        }

        debugPrint(
            '🔔 [NOTIF] Планируем "${lesson.subject}" на $reminderTime (пара в $lessonStart)');

        await _localPlugin.zonedSchedule(
          lesson.id.hashCode,
          'Скоро пара',
          '${lesson.subject} · ${lesson.room} · ${lesson.time}',
          reminderTime,
          NotificationDetails(
            android: const AndroidNotificationDetails(
              'lesson_reminders',
              'Напоминания о парах',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          // ✅ На Android 14 без разрешения используем неточный режим
          androidScheduleMode: canScheduleExact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        scheduled++;
      } catch (e) {
        debugPrint('🔔 [NOTIF] Ошибка для пары "${lesson.subject}": $e');
      }
    }

    debugPrint('🔔 [NOTIF] Запланировано: $scheduled из ${lessons.length}');
  }

  /// Разовые напоминания за 10 минут до каждой пары из списка.
  /// В отличие от старого метода учитывает чётность недели и не повторяет
  /// пару каждую неделю. Для iOS ограничивает число уведомлений (лимит 64).
  static Future<void> scheduleLessonReminderList(
      List<LessonReminder> reminders) async {
    await _localPlugin.cancelAll();
    if (!SettingsService.instance.notificationsEnabled) return;
    if (reminders.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);
    bool canScheduleExact = false;
    final androidPlugin = _localPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      canScheduleExact =
          await androidPlugin.canScheduleExactNotifications() ?? false;
    }

    final sorted = List<LessonReminder>.from(reminders)
      ..sort((a, b) => a.start.compareTo(b.start));

    int scheduled = 0;
    for (final r in sorted) {
      if (scheduled >= 60) break;
      try {
        final reminderTime = tz.TZDateTime.from(r.start, tz.local)
            .subtract(const Duration(minutes: 10));
        if (reminderTime.isBefore(now)) continue;

        await _localPlugin.zonedSchedule(
          r.key.hashCode & 0x7fffffff,
          'Скоро пара',
          '${r.subject} · ${r.room} · ${r.time}',
          reminderTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'lesson_reminders',
              'Напоминания о парах',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: canScheduleExact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
        );
        scheduled++;
      } catch (e) {
        debugPrint('🔔 [NOTIF] Ошибка напоминания "${r.subject}": $e');
      }
    }
    debugPrint('🔔 [NOTIF] Запланировано напоминаний: $scheduled');
  }

  static Future<void> testNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    await _localPlugin.zonedSchedule(
      999,
      'Тест уведомления',
      'Если вы видите это — уведомления работают!',
      now.add(const Duration(seconds: 10)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lesson_reminders',
          'Напоминания о парах',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint(
        '🔔 [NOTIF] Тест запланирован на ${now.add(const Duration(seconds: 10))}');
  }

  static DateTime _nextDateForWeekday(DateTime now, int dayIndex) {
    final targetWeekday = dayIndex + 1;
    var diff = targetWeekday - now.weekday;
    if (diff < 0) diff += 7;
    if (diff == 0) return now;
    return now.add(Duration(days: diff));
  }
}
