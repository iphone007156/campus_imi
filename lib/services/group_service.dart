import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_models.dart';

class GroupRepo {
  GroupRepo._();
  static final instance = GroupRepo._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _supabase = Supabase.instance.client;

  String get uid => _auth.currentUser!.uid;

  String _name = 'Студент';

  /// Группа и роли текущего пользователя
  Future<GroupAccess> myAccess() async {
    final d = await _db.doc('users/$uid').get();
    final m = d.data() ?? {};
    final g = (m['group'] as String?)?.trim();
    _name = (m['name'] as String?)?.trim().isNotEmpty == true ? m['name'] : 'Студент';

    List<GroupRole> userRoles = [];

    // Читаем массив ролей (новый формат)
    final rawRoles = m['roles'];
    if (rawRoles is List) {
      userRoles = rolesFromStringList(rawRoles);
    }
    // Обратная совместимость (старый формат)
    else if (m['groupRole'] != null) {
      userRoles = [roleFromString(m['groupRole'] as String?)];
    } else {
      userRoles = [GroupRole.student];
    }

    // Если глобальная роль admin, добавляем её
    if (m['role'] == 'admin' && !userRoles.contains(GroupRole.admin)) {
      userRoles.add(GroupRole.admin);
    }

    return GroupAccess(group: (g == null || g.isEmpty) ? null : g, roles: userRoles, name: _name);
  }

  String _sanitizeFileName(String originalName) {
    final lastDotIndex = originalName.lastIndexOf('.');
    String namePart = originalName;
    String extension = '.bin';

    if (lastDotIndex != -1) {
      namePart = originalName.substring(0, lastDotIndex);
      extension = originalName.substring(lastDotIndex);
    }

    namePart = namePart.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');

    if (namePart.isEmpty) namePart = 'file';
    if (namePart.startsWith('.') || namePart.startsWith('_')) namePart = 'file$namePart';
    if (namePart.length > 50) namePart = namePart.substring(0, 50);

    return '$namePart$extension';
  }

  Stream<List<MaterialItem>> materials(String groupId, String category) {
    return _db
        .collection('groups/$groupId/materials')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(MaterialItem.fromDoc).toList());
  }

  Future<void> addMaterial({
    required String groupId,
    required String category,
    required String title,
    required String description,
    required String discipline,
    required String teacher,
    DateTime? deadline,
    List<PlatformFile> files = const [],
  }) async {
    final uploaded = <FileInfo>[];

    for (final f in files) {
      if (f.path == null) continue;
      if (f.size > 50 * 1024 * 1024) throw Exception('Файл "${f.name}" больше 50 МБ');

      final safeName = _sanitizeFileName(f.name);
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$safeName';
      print('Uploading file to Supabase: $uniqueFileName');

      try {
        final fileBytes = await File(f.path!).readAsBytes();
        await _supabase.storage.from('materials').uploadBinary(uniqueFileName, fileBytes);
        final publicUrl = _supabase.storage.from('materials').getPublicUrl(uniqueFileName);
        uploaded.add(FileInfo(name: f.name, url: publicUrl, size: f.size));
      } catch (e) {
        throw Exception('Ошибка загрузки файла ${f.name}: $e');
      }
    }

    await _db.collection('groups/$groupId/materials').add({
      'category': category,
      'title': title,
      'description': description,
      'discipline': discipline,
      'teacher': teacher,
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline),
      'files': uploaded.map((e) => e.toMap()).toList(),
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMaterial(String groupId, String id) =>
      _db.doc('groups/$groupId/materials/$id').delete();

  Stream<List<ChatMessage>> chat(String groupId) {
    return _db
        .collection('groups/$groupId/chat')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendMessage(String groupId, String text) {
    return _db.collection('groups/$groupId/chat').add({
      'authorId': uid,
      'authorName': _name,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage(String groupId, String id) =>
      _db.doc('groups/$groupId/chat/$id').delete();
}