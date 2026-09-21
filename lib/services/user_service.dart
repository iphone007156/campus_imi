import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ НОВЫЙ МЕТОД: загрузить всех пользователей ОДНИМ запросом
  Future<Map<String, Map<String, dynamic>>> getUsersByIds(
      List<String> uids) async {
    if (uids.isEmpty) return {};

    final Map<String, Map<String, dynamic>> result = {};

    // Firestore позволяет максимум 10 в whereIn
    for (int i = 0; i < uids.length; i += 10) {
      final chunk = uids.sublist(
        i,
        i + 10 > uids.length ? uids.length : i + 10,
      );

      try {
        final snapshot = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in snapshot.docs) {
          result[doc.id] = doc.data();
        }
      } catch (e) {
        print('❌ Ошибка загрузки чанка: $e');
      }
    }

    return result;
  }

  /// Получить модель текущего пользователя
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromMap(user.uid, doc.data()!);
    } catch (e) {
      print('❌ Ошибка получения пользователя: $e');
      return null;
    }
  }

  /// Получить роль текущего пользователя
  Future<UserRole> getCurrentUserRole() async {
    final user = await getCurrentUser();
    return user?.role ?? UserRole.student;
  }

  /// Получить пользователя по uid
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      return UserModel.fromMap(uid, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Сменить роль пользователя (только для админа)
  Future<void> updateUserRole(String uid, UserRole newRole) async {
    final currentUser = await getCurrentUser();

    if (currentUser?.role != UserRole.admin) {
      throw Exception('Только админ может менять роли');
    }

    await _db.collection('users').doc(uid).update({
      'role': newRole.value,
    });
  }

  /// Обновить баллы пользователя
  Future<void> updateUnionPoints(String uid, int points) async {
    await _db.collection('users').doc(uid).update({
      'unionPoints': points,
    });
  }
}