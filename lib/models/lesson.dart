import 'package:flutter/material.dart';

enum LessonType { lecture, lab, seminar }

extension LessonTypeExtension on LessonType {
  String get label {
    switch (this) {
      case LessonType.lecture:
        return 'Лекция';
      case LessonType.lab:
        return 'Лаб. работа';
      case LessonType.seminar:
        return 'Семинар';
    }
  }

  Color get color {
    switch (this) {
      case LessonType.lecture:
        return const Color(0xFF3D6FA3);
      case LessonType.lab:
        return const Color(0xFF2E7D52);
      case LessonType.seminar:
        return const Color(0xFF8A5A00);
    }
  }
}

class Lesson {
  final String id;
  final String time;
  final String subject;
  final String room;
  final String teacher;
  final String type;
  final int dayIndex;
  final String group;
  final int week; // 0 - общая, 1 - нечетная, 2 - четная

  const Lesson({
    required this.id,
    required this.time,
    required this.subject,
    required this.room,
    required this.teacher,
    required this.type,
    required this.dayIndex,
    required this.group,
    this.week = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'subject': subject,
      'room': room,
      'teacher': teacher,
      'type': type,
      'dayIndex': dayIndex,
      'group': group,
      'week': week,
    };
  }

  factory Lesson.fromMap(String id, Map<String, dynamic> map) {
    return Lesson(
      id: id,
      time: map['time'] ?? '',
      subject: map['subject'] ?? '',
      room: map['room'] ?? '',
      teacher: map['teacher'] ?? '',
      type: map['type'] ?? '',
      dayIndex: int.tryParse(map['dayIndex']?.toString() ?? '0') ?? 0,
      group: map['group'] ?? '',
      // ВАЖНО: конвертируем строку в число
      week: int.tryParse(map['week']?.toString() ?? '0') ?? 0,
    );
  }

  Lesson copyWith({
    String? id,
    String? time,
    String? subject,
    String? room,
    String? teacher,
    String? type,
    int? dayIndex,
    String? group,
    int? week,
  }) {
    return Lesson(
      id: id ?? this.id,
      time: time ?? this.time,
      subject: subject ?? this.subject,
      room: room ?? this.room,
      teacher: teacher ?? this.teacher,
      type: type ?? this.type,
      dayIndex: dayIndex ?? this.dayIndex,
      group: group ?? this.group,
      week: week ?? this.week,
    );
  }

  List<String> get timeParts => time.split('-');
  String get startTime => timeParts.isNotEmpty ? timeParts[0].trim() : '';
  String get endTime => timeParts.length > 1 ? timeParts[1].trim() : '';

  @override
  String toString() => 'Lesson(id: $id, subject: $subject, time: $time)';
}