import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===== МЕРОПРИЯТИЯ =====
  Stream<List<Event>> getEvents() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Event.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<void> addEvent(Event event) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) throw Exception('Профиль не найден');

    final role = UserModel.parseRole(userDoc.data()?['role']);

    if (!role.canCreateEvents) {
      throw Exception('Только активисты могут создавать мероприятия');
    }

    if (role == UserRole.activist && event.points > 20) {
      throw Exception('Активист может ставить не более 20 баллов');
    }

    await _db.collection('events').add(event.toMap());
  }

  Future<void> updateEvent(Event event) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final role = UserModel.parseRole(userDoc.data()?['role']);

    final canEdit = user.uid == event.organizerId || role == UserRole.admin;

    if (!canEdit) {
      throw Exception('Нет прав на редактирование');
    }

    if (role == UserRole.activist && event.points > 20) {
      throw Exception('Активист может ставить не более 20 баллов');
    }

    await _db.collection('events').doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final eventDoc = await _db.collection('events').doc(eventId).get();
    if (!eventDoc.exists) return;

    final event = Event.fromMap(eventId, eventDoc.data()!);

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final role = UserModel.parseRole(userDoc.data()?['role']);

    final canDelete = user.uid == event.organizerId || role == UserRole.admin;

    if (!canDelete) {
      throw Exception('Нет прав на удаление');
    }

    await _db.collection('events').doc(eventId).delete();
  }

  // ===== ЗАПИСЬ / ОТПИСКА =====
  Future<void> joinEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db.collection('events').doc(eventId).get();
    if (doc.exists) {
      final event = Event.fromMap(doc.id, doc.data()!);
      if (event.isFinished) {
        throw Exception('Мероприятие завершено. Запись закрыта.');
      }
    }

    await _db.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayUnion([user.uid]),
      'registeredAt.${user.uid}': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db.collection('events').doc(eventId).get();
    if (doc.exists) {
      final event = Event.fromMap(doc.id, doc.data()!);
      if (event.isFinished) {
        throw Exception('Мероприятие завершено. Отписка закрыта.');
      }
    }

    await _db.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayRemove([user.uid]),
      'registeredAt.${user.uid}': FieldValue.delete(),
    });
  }

  // ===== ОТМЕТКА ПОСЕЩЕНИЯ =====
  Future<void> markAttended(String eventId, String uid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final eventDoc = await _db.collection('events').doc(eventId).get();
    if (!eventDoc.exists) return;

    final event = Event.fromMap(eventId, eventDoc.data()!);

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final role = UserModel.parseRole(userDoc.data()?['role']);

    final canMark = user.uid == event.organizerId || role == UserRole.admin;

    if (!canMark) {
      throw Exception('Нет прав на отметку посещения');
    }

    await _db.collection('events').doc(eventId).update({
      'attended': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> markNotAttended(String eventId, String uid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final eventDoc = await _db.collection('events').doc(eventId).get();
    if (!eventDoc.exists) return;

    final event = Event.fromMap(eventId, eventDoc.data()!);

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final role = UserModel.parseRole(userDoc.data()?['role']);

    final canMark = user.uid == event.organizerId || role == UserRole.admin;

    if (!canMark) {
      throw Exception('Нет прав на отметку посещения');
    }

    await _db.collection('events').doc(eventId).update({
      'attended': FieldValue.arrayRemove([uid]),
    });
  }

  // ✅ ОТМЕТИТЬ ВСЕХ СРАЗУ
  Future<void> markAllAttended(String eventId, List<String> uids) async {
    if (uids.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final eventDoc = await _db.collection('events').doc(eventId).get();
    if (!eventDoc.exists) return;

    final event = Event.fromMap(eventId, eventDoc.data()!);

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final role = UserModel.parseRole(userDoc.data()?['role']);

    final canMark = user.uid == event.organizerId || role == UserRole.admin;

    if (!canMark) {
      throw Exception('Нет прав на отметку посещения');
    }

    await _db.collection('events').doc(eventId).update({
      'attended': FieldValue.arrayUnion(uids),
    });
  }

  // ✅ СНЯТЬ ОТМЕТКУ СО ВСЕХ
  Future<void> unmarkAllAttended(String eventId, List<String> uids) async {
    if (uids.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final eventDoc = await _db.collection('events').doc(eventId).get();
    if (!eventDoc.exists) return;

    final event = Event.fromMap(eventId, eventDoc.data()!);

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final role = UserModel.parseRole(userDoc.data()?['role']);

    final canMark = user.uid == event.organizerId || role == UserRole.admin;

    if (!canMark) {
      throw Exception('Нет прав на отметку посещения');
    }

    await _db.collection('events').doc(eventId).update({
      'attended': FieldValue.arrayRemove(uids),
    });
  }

  // ===== ЗАВЕРШЕНИЕ (✅ ИСПРАВЛЕНО) =====
  Future<void> finalizeEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db.collection('events').doc(eventId).get();
    if (!doc.exists) return;

    final event = Event.fromMap(doc.id, doc.data()!);

    // Проверка: уже завершено?
    if (event.finalized) {
      throw Exception('Мероприятие уже завершено');
    }

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final role = UserModel.parseRole(userDoc.data()?['role']);

    final canFinalize = user.uid == event.organizerId || role == UserRole.admin;

    if (!canFinalize) {
      throw Exception('Нет прав на завершение');
    }

    // ✅ Используем batch для атомарного начисления
    final batch = _db.batch();

    for (String uid in event.attended) {
      final uRef = _db.collection('users').doc(uid);
      final uDoc = await uRef.get();
      if (uDoc.exists) {
        final data = uDoc.data() ?? {};
        final currentPoints =
            int.tryParse(data['unionPoints']?.toString() ?? '0') ?? 0;

        batch.update(uRef, {
          'unionPoints': currentPoints + event.points,
        });
      }
    }

    // Помечаем мероприятие завершённым
    batch.update(_db.collection('events').doc(eventId), {
      'finalized': true,
      'finalizedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    print('✅ Начислено ${event.points} баллов ${event.attended.length} участникам');
  }

  // ===== БАЛЛЫ =====
  Future<int> getUserTotalPoints() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return 0;

    return int.tryParse(doc.data()?['unionPoints']?.toString() ?? '0') ?? 0;
  }

  Future<bool> isUserParticipant(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db.collection('events').doc(eventId).get();
    if (!doc.exists) return false;

    final participants = List<String>.from(doc.data()?['participants'] ?? []);
    return participants.contains(user.uid);
  }

  // ===== РОЛЬ =====
  Future<UserRole> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return UserRole.student;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return UserRole.student;
      return UserModel.parseRole(doc.data()?['role']);
    } catch (e) {
      return UserRole.student;
    }
  }
}