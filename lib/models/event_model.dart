import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String location;
  final int points;
  final String organizer;
  final String organizerId;
  final String imageUrl;
  final String imageBase64;
  final List<String> participants;
  final Map<String, dynamic> registeredAt;
  final List<String> attended;
  final DateTime? endTime;
  final bool finalized;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.points,
    required this.organizer,
    required this.organizerId,
    required this.imageUrl,
    this.imageBase64 = '',
    required this.participants,
    this.registeredAt = const {},
    this.attended = const [],
    this.endTime,
    this.finalized = false,
    required this.createdAt,
  });

  bool get isFinished {
    if (finalized) return true;
    if (endTime == null) return false;
    return DateTime.now().isAfter(endTime!);
  }

  bool get hasImage => imageUrl.isNotEmpty || imageBase64.isNotEmpty;

  DateTime? getRegisteredAt(String uid) {
    final value = registeredAt[uid];
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool wasRegisteredAfterEnd(String uid) {
    final reg = getRegisteredAt(uid);
    if (reg == null || endTime == null) return false;
    return reg.isAfter(endTime!);
  }

  factory Event.fromMap(String id, Map<String, dynamic> map) {
    return Event(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      points: int.tryParse(map['points']?.toString() ?? '0') ?? 0,
      organizer: map['organizer'] ?? '',
      organizerId: map['organizerId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      imageBase64: map['imageBase64'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      registeredAt: Map<String, dynamic>.from(map['registeredAt'] ?? {}),
      attended: List<String>.from(map['attended'] ?? []),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      finalized: map['finalized'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'location': location,
      'points': points,
      'organizer': organizer,
      'organizerId': organizerId,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'participants': participants,
      'registeredAt': registeredAt,
      'attended': attended,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'finalized': finalized,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? time,
    String? location,
    int? points,
    String? organizer,
    String? organizerId,
    String? imageUrl,
    String? imageBase64,
    List<String>? participants,
    Map<String, dynamic>? registeredAt,
    List<String>? attended,
    DateTime? endTime,
    bool? finalized,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      points: points ?? this.points,
      organizer: organizer ?? this.organizer,
      organizerId: organizerId ?? this.organizerId,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      participants: participants ?? this.participants,
      registeredAt: registeredAt ?? this.registeredAt,
      attended: attended ?? this.attended,
      endTime: endTime ?? this.endTime,
      finalized: finalized ?? this.finalized,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}