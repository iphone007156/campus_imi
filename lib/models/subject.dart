import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String studentUid;
  final String group;
  final String name;
  final String type;      // Экзамен, Зачет, Диф.зачет
  final String teacher;
  final int? grade;       // 5, 4, 3, 2 (null, если зачет)
  final String gradeText; // "Зачет", "Незачет"
  final int semester;
  final int hours;
  final double credits;

  const Subject({
    required this.id,
    required this.studentUid,
    required this.group,
    required this.name,
    required this.type,
    required this.teacher,
    this.grade,
    this.gradeText = '',
    required this.semester,
    this.hours = 0,
    this.credits = 0,
  });

  factory Subject.fromMap(String id, Map<String, dynamic> map) {
    return Subject(
      id: id,
      studentUid: map['studentUid']?.toString() ?? '',
      group: map['group']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      teacher: map['teacher']?.toString() ?? '',
      grade: map['grade'] is int ? map['grade'] : null,
      gradeText: map['gradeText']?.toString() ?? '',
      semester: int.tryParse(map['semester']?.toString() ?? '1') ?? 1,
      hours: int.tryParse(map['hours']?.toString() ?? '0') ?? 0,
      credits: (map['credits'] is num) ? (map['credits'] as num).toDouble() : 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'studentUid': studentUid,
    'group': group,
    'name': name,
    'type': type,
    'teacher': teacher,
    'grade': grade,
    'gradeText': gradeText,
    'semester': semester,
    'hours': hours,
    'credits': credits,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  // Фабричный конструктор для создания пустого объекта
  factory Subject.empty() {
    return const Subject(
      id: '',
      studentUid: '',
      group: '',
      name: '',
      grade: null,
      gradeText: '',
      type: '',
      teacher: '',
      semester: 1,
    );
  }

  // Копирование с изменениями
  Subject copyWith({
    String? id,
    String? studentUid,
    String? group,
    String? name,
    int? grade,
    String? gradeText,
    String? type,
    String? teacher,
    int? semester,
    int? hours,
    double? credits,
  }) {
    return Subject(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      group: group ?? this.group,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      gradeText: gradeText ?? this.gradeText,
      type: type ?? this.type,
      teacher: teacher ?? this.teacher,
      semester: semester ?? this.semester,
      hours: hours ?? this.hours,
      credits: credits ?? this.credits,
    );
  }

  @override
  String toString() => 'Subject(id: $id, name: $name, grade: $grade)';
}