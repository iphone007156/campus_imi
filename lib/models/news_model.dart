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
  final String imageUrl;
  final String imageBase64;
  final DateTime createdAt;

  News({
    required this.id,
    required this.title,
    required this.body,
    required this.shortDescription,
    required this.date,
    required this.category,
    required this.authorName,
    required this.authorId,
    required this.imageUrl,
    this.imageBase64 = '',
    required this.createdAt,
  });

  bool get hasImage => imageUrl.isNotEmpty || imageBase64.isNotEmpty;

  /// «5 мин назад», «2 ч назад», «Вчера»
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
    return News(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      date: map['date'] ?? '',
      category: map['category'] ?? 'События',
      authorName: map['authorName'] ?? '',
      authorId: map['authorId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      imageBase64: map['imageBase64'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}