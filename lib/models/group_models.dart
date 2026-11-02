import 'package:cloud_firestore/cloud_firestore.dart';

// Единый перечень всех возможных ролей в системе
enum GroupRole { student, deputy, head, activist, sport, culture, admin }

extension GroupRoleX on GroupRole {
  // Человекочитаемое название
  String get title {
    switch (this) {
      case GroupRole.head: return 'Староста';
      case GroupRole.deputy: return 'Заместитель';
      case GroupRole.activist: return 'Активист';
      case GroupRole.sport: return 'Спорт-сектор';
      case GroupRole.culture: return 'Культ-масс';
      case GroupRole.admin: return 'Админ';
      default: return 'Студент';
    }
  }

  // Строковый ключ для сохранения в Firestore
  String get key {
    switch (this) {
      case GroupRole.head: return 'head';
      case GroupRole.deputy: return 'deputy';
      case GroupRole.activist: return 'activist';
      case GroupRole.sport: return 'sport';
      case GroupRole.culture: return 'culture';
      case GroupRole.admin: return 'admin';
      default: return 'student';
    }
  }

  // Проверки прав (для удобства в UI)
  bool get canEdit => this == GroupRole.head || this == GroupRole.deputy || this == GroupRole.admin;
}

// Парсинг списка строк из Firestore в список enum
List<GroupRole> rolesFromStringList(List<dynamic>? list) {
  if (list == null || list.isEmpty) return [GroupRole.student];
  return list.map((e) {
    final str = e.toString();
    return GroupRole.values.firstWhere(
          (role) => role.key == str,
      orElse: () => GroupRole.student,
    );
  }).toSet().toList(); // toSet убирает дубликаты
}

// Конвертация одиночной строки (для обратной совместимости)
GroupRole roleFromString(String? s) {
  return GroupRole.values.firstWhere(
        (role) => role.key == s,
    orElse: () => GroupRole.student,
  );
}

class GroupAccess {
  final String? group;
  final List<GroupRole> roles; // ТЕПЕРЬ СПИСОК РОЛЕЙ
  final String name;

  const GroupAccess({required this.group, required this.roles, required this.name});

  // Удобные геттеры
  bool get canEdit => roles.any((r) => r.canEdit);
  bool get isAdmin => roles.contains(GroupRole.admin);
  bool get isHead => roles.contains(GroupRole.head);
  bool get isActivist => roles.contains(GroupRole.activist);
}

class Cat {
  static const srs = 'srs';
  static const lecture = 'lecture';
  static const announcement = 'announcement';
}

class FileInfo {
  final String name;
  final String url;
  final int size;
  const FileInfo({required this.name, required this.url, required this.size});

  Map<String, dynamic> toMap() => {'name': name, 'url': url, 'size': size};

  factory FileInfo.fromMap(Map<String, dynamic> m) => FileInfo(
    name: m['name'] ?? 'file',
    url: m['url'] ?? '',
    size: (m['size'] ?? 0) as int,
  );
}

class MaterialItem {
  final String id;
  final String category;
  final String title;
  final String description;
  final String discipline;
  final String teacher;
  final DateTime? deadline;
  final List<FileInfo> files;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MaterialItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.discipline,
    required this.teacher,
    required this.deadline,
    required this.files,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get edited =>
      updatedAt != null && createdAt != null && updatedAt!.isAfter(createdAt!.add(const Duration(seconds: 5)));

  factory MaterialItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    DateTime? ts(String k) => (m[k] as Timestamp?)?.toDate();
    return MaterialItem(
      id: d.id,
      category: m['category'] ?? '',
      title: m['title'] ?? '',
      description: m['description'] ?? '',
      discipline: m['discipline'] ?? '',
      teacher: m['teacher'] ?? '',
      deadline: ts('deadline'),
      files: ((m['files'] ?? []) as List)
          .map((e) => FileInfo.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      createdBy: m['createdBy'] ?? '',
      createdAt: ts('createdAt'),
      updatedAt: ts('updatedAt'),
    );
  }
}

class ChatMessage {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return ChatMessage(
      id: d.id,
      authorId: m['authorId'] ?? '',
      authorName: m['authorName'] ?? 'Студент',
      text: m['text'] ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}