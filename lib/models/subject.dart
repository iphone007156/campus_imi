class Subject {
  final String id;
  final String name;
  final int? grade;
  final String type;
  final String teacher;

  const Subject({
    required this.id,
    required this.name,
    this.grade,
    required this.type,
    required this.teacher,
  });

  // Фабричный конструктор для создания пустого объекта
  factory Subject.empty() {
    return const Subject(
      id: '',
      name: '',
      grade: null,
      type: '',
      teacher: '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'grade': grade,
      'type': type,
      'teacher': teacher,
    };
  }

  factory Subject.fromMap(String id, Map<String, dynamic> map) {
    return Subject(
      id: id,
      name: map['name']?.toString() ?? '',
      grade: map['grade'] is int ? map['grade'] : null,
      type: map['type']?.toString() ?? '',
      teacher: map['teacher']?.toString() ?? '',
    );
  }

  // Копирование с изменениями
  Subject copyWith({
    String? id,
    String? name,
    int? grade,
    String? type,
    String? teacher,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      type: type ?? this.type,
      teacher: teacher ?? this.teacher,
    );
  }

  @override
  String toString() => 'Subject(id: $id, name: $name, grade: $grade)';
}