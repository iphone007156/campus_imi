import 'dart:typed_data';
import 'package:excel/excel.dart';

class ParsedLesson {
  final String group;
  final int dayIndex;
  final int week;
  final String time;
  final String subject;
  final String teacher;
  final String room;
  final String type;

  ParsedLesson({
    required this.group,
    required this.dayIndex,
    required this.week,
    required this.time,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
    'group': group,
    'dayIndex': dayIndex,
    'week': week,
    'time': time,
    'subject': subject,
    'teacher': teacher,
    'room': room,
    'type': type,
  };
}

class ExcelParseResult {
  final List<ParsedLesson> lessons;
  final List<String> errors;
  ExcelParseResult(this.lessons, this.errors);
}

class ExcelScheduleParser {
  static const List<String> _timeSlots = [
    '8:00-9:35', '9:50-11:25', '11:40-13:15',
    '14:00-15:35', '15:50-17:25', '17:40-19:15',
  ];

  static const Map<String, int> _dayMap = {
    'понедельник': 0, 'вторник': 1, 'среда': 2,
    'четверг': 3, 'пятница': 4, 'суббота': 5,
  };

  static ExcelParseResult parse(Uint8List bytes) {
    final lessons = <ParsedLesson>[];
    final errors = <String>[];

    final excel = Excel.decodeBytes(bytes);

    for (final sheetName in excel.tables.keys) {
      if (_isServiceSheet(sheetName)) continue;
      final sheet = excel.tables[sheetName]!;
      if (sheet.rows.isEmpty) continue;
      try {
        _parseSheet(sheet, sheetName, lessons, errors);
      } catch (e) {
        errors.add('Лист "$sheetName": $e');
      }
    }

    return ExcelParseResult(lessons, errors);
  }

  static bool _isServiceSheet(String name) {
    final n = name.toLowerCase();
    return n.contains('титул') ||
        n.contains('недел') ||
        n.contains('звонк') ||
        n.contains('ауд') ||
        n.contains('корпус') ||
        n.contains('лист');
  }

  static void _parseSheet(
      Sheet sheet,
      String sheetName,
      List<ParsedLesson> out,
      List<String> errors,
      ) {
    // 1. Найти строку с заголовками групп
    int headerRowIdx = -1;
    for (var r = 0; r < sheet.rows.length && r < 10; r++) {
      final row = sheet.rows[r];
      for (var c = 2; c < row.length; c++) {
        final v = _clean(_cell(row, c));
        if (RegExp(r'\d{2}').hasMatch(v) && v.contains('-')) {
          headerRowIdx = r;
          break;
        }
      }
      if (headerRowIdx != -1) break;
    }

    if (headerRowIdx == -1) {
      errors.add('Лист "$sheetName": не найдена строка с группами');
      return;
    }

    // 2. Собираем карту: startCol -> имя группы
    final headerRow = sheet.rows[headerRowIdx];
    final groupColumns = <int, String>{};
    for (var c = 2; c < headerRow.length; c++) {
      final v = _clean(_cell(headerRow, c));
      final name = v.split(RegExp(r'[\s\(]+')).first;
      if (name.isNotEmpty && RegExp(r'\d').hasMatch(name)) {
        groupColumns[c] = name;
      }
    }

    if (groupColumns.isEmpty) {
      errors.add('Лист "$sheetName": не распознаны группы');
      return;
    }

    // 3. Идём по строкам
    int currentDay = -1;
    String currentTime = '';

    for (var r = headerRowIdx + 1; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      if (row.isEmpty) continue;

      final a = _clean(_cell(row, 0)).toLowerCase();
      final b = _clean(_cell(row, 1));

      if (a.startsWith('зам.') || a.startsWith('зам ')) break;

      if (_dayMap.containsKey(a)) {
        currentDay = _dayMap[a]!;
      }

      if (b.isNotEmpty) {
        final t = _normalizeTime(b);
        if (t.isNotEmpty) currentTime = t;
      }

      if (currentDay == -1 || currentTime.isEmpty) continue;

      // 4. Разбираем блоки групп
      for (final entry in groupColumns.entries) {
        final startCol = entry.key;
        final group = entry.value;

        final subject = _clean(_cell(row, startCol));
        if (subject.isEmpty) continue;

        final typeRaw = _clean(_cell(row, startCol + 1));
        final teacherRaw = _clean(_cell(row, startCol + 2));
        final roomRaw = _clean(_cell(row, startCol + 3));

        _splitAndAdd(
          out: out,
          group: group,
          day: currentDay,
          time: currentTime,
          subjectRaw: subject,
          typeRaw: typeRaw,
          teacherRaw: teacherRaw,
          roomRaw: roomRaw,
        );
      }
    }
  }

  static void _splitAndAdd({
    required List<ParsedLesson> out,
    required String group,
    required int day,
    required String time,
    required String subjectRaw,
    required String typeRaw,
    required String teacherRaw,
    required String roomRaw,
  }) {
    final teachers = teacherRaw
        .split(RegExp(r'<br\s*/?>|\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final rooms = roomRaw
        .split(RegExp(r'<br\s*/?>|\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final parts = _splitSubjects(subjectRaw);
    if (parts.isEmpty) return;

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final teacher = i < teachers.length ? teachers[i] : (teachers.isNotEmpty ? teachers.first : '');
      final room = i < rooms.length ? rooms[i] : (rooms.isNotEmpty ? rooms.first : '');

      out.add(ParsedLesson(
        group: group,
        dayIndex: day,
        week: part.week,
        time: time,
        subject: part.subject,
        teacher: teacher,
        room: room,
        type: _normalizeType(typeRaw),
      ));
    }
  }

  static List<_SubjectPart> _splitSubjects(String raw) {
    final rough = raw
        .split(RegExp(r'<br\s*/?>|\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (rough.isEmpty) return [];

    final res = <_SubjectPart>[];
    for (final chunk in rough) {
      res.addAll(_splitByStars(chunk));
    }
    return res;
  }

  static List<_SubjectPart> _splitByStars(String s) {
    final regex = RegExp(r'\*{1,2}');
    final matches = regex.allMatches(s).toList();
    if (matches.isEmpty) return [_SubjectPart(s.trim(), 0)];

    final parts = <_SubjectPart>[];
    var lastEnd = 0;
    for (final m in matches) {
      final before = s.substring(lastEnd, m.start).trim();
      final stars = m.group(0)!;
      final week = stars == '**' ? 2 : 1;
      if (before.isNotEmpty) parts.add(_SubjectPart(before, week));
      lastEnd = m.end;
    }
    final tail = s.substring(lastEnd).trim();
    if (tail.isNotEmpty) parts.add(_SubjectPart(tail, 0));
    return parts;
  }

  static String _normalizeType(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('лек')) return 'лек';
    if (r.contains('лаб')) return 'лаб';
    if (r.contains('сем')) return 'сем';
    if (r.contains('пр')) return 'пр';
    return raw.trim();
  }

  static String _normalizeTime(String raw) {
    final m = RegExp(r'(\d{1,2})[.:](\d{2})\s*[-–]+\s*(\d{1,2})[.:](\d{2})').firstMatch(raw);
    if (m == null) return '';
    final h1 = int.parse(m.group(1)!);
    final mm1 = m.group(2)!;
    final h2 = int.parse(m.group(3)!);
    final mm2 = m.group(4)!;
    final result = '$h1:$mm1-$h2:$mm2';
    return _timeSlots.contains(result) ? result : result;
  }

  static String _clean(String s) => s.replaceAll('<br>', ' ').replaceAll('\n', ' ').trim();

  static String _cell(List<Data?> row, int idx) {
    if (idx < 0 || idx >= row.length) return '';
    return row[idx]?.value?.toString() ?? '';
  }
}

class _SubjectPart {
  final String subject;
  final int week;
  _SubjectPart(this.subject, this.week);
}