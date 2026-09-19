import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, activist, admin }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.activist:
        return 'activist';
      case UserRole.admin:
        return 'admin';
    }
  }

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Студент';
      case UserRole.activist:
        return 'Активист';
      case UserRole.admin:
        return 'Администратор';
    }
  }

  int get maxPoints {
    switch (this) {
      case UserRole.student:
        return 0;
      case UserRole.activist:
        return 20;
      case UserRole.admin:
        return 999;
    }
  }

  bool get canCreateEvents {
    return this == UserRole.activist || this == UserRole.admin;
  }

  bool get canManageAllEvents {
    return this == UserRole.admin;
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String group;
  final String institute;
  final UserRole role;
  final int unionPoints;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.group,
    required this.institute,
    required this.role,
    required this.unionPoints,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      group: map['group'] ?? '',
      institute: map['institute'] ?? 'ИМИ СВФУ',
      role: parseRole(map['role']),
      unionPoints: int.tryParse(map['unionPoints']?.toString() ?? '0') ?? 0,
    );
  }

  static UserRole parseRole(dynamic value) {
    switch (value?.toString()) {
      case 'admin':
        return UserRole.admin;
      case 'activist':
        return UserRole.activist;
      default:
        return UserRole.student;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'group': group,
      'institute': institute,
      'role': role.value,
      'unionPoints': unionPoints,
    };
  }
}