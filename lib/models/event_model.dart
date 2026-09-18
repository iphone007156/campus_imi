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
  final String organizerId;  // ← ДОБАВЛЕНО
  final String imageUrl;
  final List<String> participants;
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
    required this.organizerId,  // ← ДОБАВЛЕНО
    required this.imageUrl,
    required this.participants,
    required this.createdAt,
  });

  factory Event.fromMap(String id, Map<String, dynamic> map) {
    return Event(
      id: id,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      points: int.tryParse(map['points']?.toString() ?? '0') ?? 0,
      organizer: map['organizer']?.toString() ?? '',
      organizerId: map['organizerId']?.toString() ?? '',  // ← ДОБАВЛЕНО
      imageUrl: map['imageUrl']?.toString() ?? '',
      participants: List<String>.from(map['participants'] ?? []),
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
      'points': points.toString(),
      'organizer': organizer,
      'organizerId': organizerId,  // ← ДОБАВЛЕНО
      'imageUrl': imageUrl,
      'participants': participants,
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
    String? organizerId,  // ← ДОБАВЛЕНО
    String? imageUrl,
    List<String>? participants,
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
      organizerId: organizerId ?? this.organizerId,  // ← ДОБАВЛЕНО
      imageUrl: imageUrl ?? this.imageUrl,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}