import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/lesson.dart';
import '../models/subject.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final Map<String, DocumentSnapshot> _userCache = {};

  // --- User Management ---
  Future<DocumentSnapshot> getUserData(String uid) async {
    if (_userCache.containsKey(uid)) {
      return _userCache[uid]!;
    }
    try {
      final doc = await _db.collection('users').doc(uid).get();
      _userCache[uid] = doc;
      return doc;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      rethrow;
    }
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await getUserData(uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['role'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  // --- Lessons (Schedule) ---
  Stream<List<Lesson>> getAllLessons() {
    return _db
        .collection('lessons')
        .orderBy('dayIndex')
        .orderBy('time')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Lesson.fromMap(doc.id, doc.data()))
        .toList());
  }

  Stream<List<Lesson>> getLessons(int dayIndex) {
    return _db
        .collection('lessons')
        .where('dayIndex', isEqualTo: dayIndex)
        .orderBy('time')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Lesson.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<void> addLesson(Lesson lesson) {
    return _db.collection('lessons').add(lesson.toMap());
  }

  Future<void> updateLesson(Lesson lesson) {
    return _db.collection('lessons').doc(lesson.id).update(lesson.toMap());
  }

  Future<void> deleteLesson(String id) {
    return _db.collection('lessons').doc(id).delete();
  }

  // --- Subjects (Gradebook) ---
  Stream<List<Subject>> getSubjects() {
    return _db.collection('subjects').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Subject.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<void> addSubject(Subject subject) {
    return _db.collection('subjects').add(subject.toMap());
  }

  Future<void> updateSubject(Subject subject) {
    return _db.collection('subjects').doc(subject.id).update(subject.toMap());
  }

  Future<void> deleteSubject(String id) {
    return _db.collection('subjects').doc(id).delete();
  }

  void clearCache() {
    _userCache.clear();
  }
}