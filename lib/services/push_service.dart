import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'settings_service.dart'; // ✅ добавлено

class PushService {
  // ✅ Вставьте вашу ссылку из Render (без слеша в конце)
  static const String _serverUrl = "https://campus-push-api.onrender.com";

  /// Отправка пуша всем подписанным пользователям
  static Future<void> sendToAll({
    required String title,
    required String message,
  }) async {
    // ✅ Если у пользователя отключены уведомления — не отправляем
    if (!SettingsService.instance.notificationsEnabled) {
      debugPrint('📨 [PUSH] Уведомления отключены, отправка пропущена');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/send-push'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          "title": title,
          "message": message,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Push успешно отправлен через сервер");
      } else {
        debugPrint("❌ Ошибка сервера: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Ошибка сети: $e");
    }
  }

  /// Отправка пуша конкретному пользователю (по его Firebase UID)
  static Future<void> sendToUser({
    required String uid,
    required String title,
    required String message,
  }) async {
    if (!SettingsService.instance.notificationsEnabled) {
      debugPrint('📨 [PUSH] Уведомления отключены, отправка пропущена');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/send-push'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          "title": title,
          "message": message,
          "segment": ["Subscribed Users"],
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Персональный push отправлен через сервер");
      } else {
        debugPrint("❌ Ошибка сервера: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Ошибка сети: $e");
    }
  }
}