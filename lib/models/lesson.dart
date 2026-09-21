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
  final int week;

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
    // ПОДДЕРЖКА ОБОИХ ВАРИАНТОВ: dayIndex и dayindex
    final dayIndexRaw = map['dayIndex'] ?? map['dayindex'];
    final weekRaw = map['week'] ?? map['Week'];

    return Lesson(
      id: id,
      time: (map['time'] ?? '').toString().trim(),
      subject: (map['subject'] ?? '').toString().trim(),
      room: (map['room'] ?? '').toString().trim(),
      teacher: (map['teacher'] ?? '').toString().trim(),
      type: (map['type'] ?? '').toString().trim(),
      dayIndex: int.tryParse(dayIndexRaw?.toString().trim() ?? '0') ?? 0,
      group: (map['group'] ?? '').toString().trim(),
      week: int.tryParse(weekRaw?.toString().trim() ?? '0') ?? 0,
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