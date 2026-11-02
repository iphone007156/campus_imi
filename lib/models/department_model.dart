import 'package:cloud_firestore/cloud_firestore.dart';

class Department {
  final String id;
  final String name;      // Полное название (Институт математики и информатики)
  final String shortName; // Аббревиатура (ИМИ)
  final String type;      // 'institute' или 'college' или 'faculty'

  Department({
    required this.id,
    required this.name,
    required this.shortName,
    required this.type,
  });

  factory Department.fromMap(String id, Map<String, dynamic> data) {
    return Department(
      id: id,
      name: data['name'] ?? '',
      shortName: data['shortName'] ?? '',
      type: data['type'] ?? 'institute',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortName': shortName,
      'type': type,
    };
  }
}