import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String title;
  final String body;
  final String shortDescription;
  final String date;
  final String category;
  final String authorName;
  final String authorId;
  final String departmentId; // ✅ ПРИВЯЗКА К ПОДРАЗДЕЛЕНИЮ
  final List<String> imageUrls;
  final String imageBase64;
  final DateTime createdAt;
  final String sourceName;
  final String sourceUrl;

  News({
    required this.id,
    required this.title,
    required this.body,
    required this.shortDescription,
    required this.date,
    required this.category,
    required this.authorName,
    required this.authorId,
    this.departmentId = '', // По умолчанию пусто (для общих новостей)
    required this.imageUrls,
    this.imageBase64 = '',
    required this.createdAt,
    this.sourceName = '',
    this.sourceUrl = '',
  });

  bool get hasImage => imageUrls.isNotEmpty || imageBase64.isNotEmpty;
  String get mainImage => imageUrls.isNotEmpty ? imageUrls.first : '';
  bool get hasSource => sourceName.isNotEmpty || sourceUrl.isNotEmpty;

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays == 1) return 'вчера';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';
    return date;
  }

  factory News.fromMap(String id, Map<String, dynamic> map) {
    List<String> urls = [];
    if (map['imageUrls'] is List) {
      urls = List<String>.from(map['imageUrls'].map((e) => e.toString()));
    } else if (map['imageUrl'] != null && map['imageUrl'].toString().isNotEmpty) {
      urls = [map['imageUrl'].toString()];
    }

    return News(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      date: map['date'] ?? '',
      category: map['category'] ?? 'События',
      authorName: map['authorName'] ?? '',
      authorId: map['authorId'] ?? '',
      departmentId: map['departmentId'] ?? '', // ✅
      imageUrls: urls,
      imageBase64: map['imageBase64'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sourceName: map['sourceName'] ?? '',
      sourceUrl: map['sourceUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'shortDescription': shortDescription,
      'date': date,
      'category': category,
      'authorName': authorName,
      'authorId': authorId,
      'departmentId': departmentId, // ✅
      'imageUrls': imageUrls,
      'imageBase64': imageBase64,
      'createdAt': Timestamp.fromDate(createdAt),
      'sourceName': sourceName,
      'sourceUrl': sourceUrl,
    };
  }
}