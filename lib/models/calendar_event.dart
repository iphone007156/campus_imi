import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String id;
  final String group;
  final int semester;
  final String component;
  final DateTime start;
  final DateTime end;
  final String duration;

  CalendarEvent({
    required this.id,
    required this.group,
    required this.semester,
    required this.component,
    required this.start,
    required this.end,
    required this.duration,
  });

  factory CalendarEvent.fromMap(String id, Map<String, dynamic> map) {
    return CalendarEvent(
      id: id,
      group: (map['group'] as String?) ?? '',
      semester: _toInt(map['semester']) ?? 1,
      component: (map['component'] as String?) ?? '',
      start: _toDate(map['start']) ?? DateTime.now(),
      end: _toDate(map['end']) ?? DateTime.now(),
      duration: (map['duration'] as String?) ?? '',
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'group': group,
      'semester': semester,
      'component': component,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'duration': duration,
    };
  }
}