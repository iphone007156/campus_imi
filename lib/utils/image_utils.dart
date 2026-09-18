import 'dart:io';              // ← ДОБАВЛЕНО
import 'dart:convert';        // ← ДОБАВЛЕНО
import 'dart:typed_data';     // ← ДОБАВЛЕНО
import 'package:flutter/material.dart';

class ImageUtils {
  // Декодирование Base64 в ImageProvider
  static ImageProvider? getImageFromBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      print('❌ Ошибка декодирования фото: $e');
      return null;
    }
  }

  // Конвертация File в Base64
  static String? imageToBase64(File image) {
    try {
      final bytes = image.readAsBytesSync();
      if (bytes.length > 1000000) {  // 1 МБ
        print('⚠️ Фото слишком большое (${bytes.length} байт)');
      }
      return base64Encode(bytes);
    } catch (e) {
      print('❌ Ошибка конвертации: $e');
      return null;
    }
  }
}