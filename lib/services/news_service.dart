import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/news_model.dart';

class NewsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Получить все новости — работает для ВСЕХ, включая гостей
  Stream<List<News>> getNews() {
    return _db
        .collection('news')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => News.fromMap(doc.id, doc.data()))
        .toList());
  }

  /// Добавить новость — только для авторизованных
  Future<void> addNews(News news) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    await _db.collection('news').add(news.toMap());
  }

  /// Удалить новость
  Future<void> deleteNews(String newsId) async {
    await _db.collection('news').doc(newsId).delete();
  }
}