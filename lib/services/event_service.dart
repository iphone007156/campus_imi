import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Получить все мероприятия
  Stream<List<Event>> getEvents() {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ Пользователь не авторизован');
      return Stream.value([]);
    }

    print('✅ Загрузка мероприятий для: ${user.email}');
    return _db
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📊 Найдено документов: ${snapshot.docs.length}');
      return snapshot.docs
          .map((doc) => Event.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Добавить мероприятие
  Future<void> addEvent(Event event) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('❌ Пользователь не авторизован');
    }

    print('✅ Создание мероприятия: ${event.title}');
    await _db.collection('events').add(event.toMap());
  }

  // Обновить мероприятие
  Future<void> updateEvent(Event event) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('❌ Пользователь не авторизован');
    }

    await _db.collection('events').doc(event.id).update(event.toMap());
    print('✅ Мероприятие обновлено: ${event.title}');
  }

  // Удалить мероприятие
  Future<void> deleteEvent(String eventId) async {  // <-- ДОБАВЛЕН МЕТОД
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('❌ Пользователь не авторизован');
    }

    await _db.collection('events').doc(eventId).delete();
    print('✅ Мероприятие удалено');
  }

  // Записаться на мероприятие
  Future<void> joinEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('❌ Пользователь не авторизован');
    }

    await _db.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayUnion([user.uid]),
    });
    print('✅ Пользователь записался на мероприятие');
  }

  // Отписаться от мероприятия
  Future<void> leaveEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('❌ Пользователь не авторизован');
    }

    await _db.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayRemove([user.uid]),
    });
    print('✅ Пользователь отписался от мероприятия');
  }

  // Получить общее количество баллов
  Future<int> getUserTotalPoints() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final events = await _db
        .collection('events')
        .where('participants', arrayContains: user.uid)
        .get();

    int total = 0;
    for (var doc in events.docs) {
      final event = Event.fromMap(doc.id, doc.data());
      total += event.points;
    }
    print('💰 Всего баллов: $total');
    return total;
  }

  // Проверить, участвует ли пользователь
  Future<bool> isUserParticipant(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db.collection('events').doc(eventId).get();
    if (!doc.exists) return false;

    final participants = List<String>.from(doc.data()?['participants'] ?? []);
    return participants.contains(user.uid);
  }
}