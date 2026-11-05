import 'package:flutter_test/flutter_test.dart';
import 'package:campus_imi/models/lesson.dart';
import 'package:campus_imi/services/schedule_service.dart';

Lesson _lesson({
  String id = '1',
  String time = '14:00-15:35',
  int dayIndex = 1, // 0 — понедельник, 1 — вторник
  int week = 0, // 0 — каждая неделя, 1 — нечётная, 2 — чётная
  String subject = 'Предмет',
}) {
  return Lesson(
    id: id,
    time: time,
    subject: subject,
    room: '326',
    teacher: '',
    type: 'пр',
    dayIndex: dayIndex,
    group: 'Г-1',
    week: week,
  );
}

void main() {
  // Понедельник 2 ноября 2026 — начало нечётной недели.
  final oddWeeks = [DateTime(2026, 11, 2)];

  group('weekNumber', () {
    test('все дни нечётной недели дают 1', () {
      expect(ScheduleService.weekNumber(DateTime(2026, 11, 2), oddWeeks), 1);
      expect(ScheduleService.weekNumber(DateTime(2026, 11, 3, 15, 30), oddWeeks), 1);
      expect(ScheduleService.weekNumber(DateTime(2026, 11, 8), oddWeeks), 1);
    });

    test('соседние недели чётные', () {
      expect(ScheduleService.weekNumber(DateTime(2026, 11, 1), oddWeeks), 2);
      expect(ScheduleService.weekNumber(DateTime(2026, 11, 9), oddWeeks), 2);
    });
  });

  group('mondayOf', () {
    test('вторник и воскресенье относятся к понедельнику своей недели', () {
      expect(ScheduleService.mondayOf(DateTime(2026, 11, 3, 18)), DateTime(2026, 11, 2));
      expect(ScheduleService.mondayOf(DateTime(2026, 11, 8)), DateTime(2026, 11, 2));
    });
  });

  group('lessonsForDate', () {
    final all = [
      _lesson(id: 'a', time: '14:00-15:35', subject: 'Каждая неделя'),
      _lesson(id: 'b', time: '09:50-11:25', week: 1, subject: 'Нечётная'),
      _lesson(id: 'c', time: '11:35-13:10', week: 2, subject: 'Чётная'),
      _lesson(id: 'd', time: '09:50-11:25', dayIndex: 0, subject: 'Другой день'),
      _lesson(id: 'e', time: 'позже', subject: 'Без времени'),
    ];

    test('учитывает день недели и чётность, сортирует по времени', () {
      final result = ScheduleService.lessonsForDate(all, DateTime(2026, 11, 3), oddWeeks);
      expect(result.map((l) => l.id).toList(), ['b', 'a', 'e']);
    });

    test('на чётной неделе показывает чётные пары', () {
      final result = ScheduleService.lessonsForDate(all, DateTime(2026, 11, 10), oddWeeks);
      expect(result.map((l) => l.id).toList(), ['c', 'a', 'e']);
    });
  });

  group('occurrenceFor', () {
    test('разбирает начало и конец пары', () {
      final occ = ScheduleService.occurrenceFor(_lesson(), DateTime(2026, 11, 3))!;
      expect(occ.start, DateTime(2026, 11, 3, 14, 0));
      expect(occ.end, DateTime(2026, 11, 3, 15, 35));
    });

    test('понимает точку вместо двоеточия', () {
      final occ = ScheduleService.occurrenceFor(_lesson(time: '9.50-11.25'), DateTime(2026, 11, 3))!;
      expect(occ.start, DateTime(2026, 11, 3, 9, 50));
    });

    test('если указано только начало, пара длится 95 минут', () {
      final occ = ScheduleService.occurrenceFor(_lesson(time: '10:00'), DateTime(2026, 11, 3))!;
      expect(occ.end, DateTime(2026, 11, 3, 11, 35));
    });

    test('неверное время не ломает расчёт', () {
      expect(ScheduleService.occurrenceFor(_lesson(time: 'abc'), DateTime(2026, 11, 3)), isNull);
      expect(ScheduleService.occurrenceFor(_lesson(time: '25:99-26:00'), DateTime(2026, 11, 3)), isNull);
    });
  });

  group('сейчас и дальше', () {
    final all = [
      _lesson(id: 'p1', time: '09:50-11:25'),
      _lesson(id: 'p2', time: '14:00-15:35'),
      _lesson(id: 'p3', time: '15:45-17:20'),
    ];
    final list = ScheduleService.occurrences(all, DateTime(2026, 11, 3), oddWeeks, days: 1);

    test('находит идущую пару', () {
      final now = DateTime(2026, 11, 3, 14, 40);
      expect(ScheduleService.current(list, now)!.lesson.id, 'p2');
      expect(ScheduleService.next(list, now)!.lesson.id, 'p3');
    });

    test('в перерыве идущей пары нет, дальше ближайшая', () {
      final now = DateTime(2026, 11, 3, 12, 0);
      expect(ScheduleService.current(list, now), isNull);
      expect(ScheduleService.next(list, now)!.lesson.id, 'p2');
    });

    test('после последней пары дальше ничего нет', () {
      final now = DateTime(2026, 11, 3, 18, 0);
      expect(ScheduleService.current(list, now), isNull);
      expect(ScheduleService.next(list, now), isNull);
    });

    test('прогресс пары от 0 до 1', () {
      final occ = list[1];
      expect(occ.progressAt(DateTime(2026, 11, 3, 14, 0)), 0.0);
      expect(occ.progressAt(DateTime(2026, 11, 3, 15, 35)), 1.0);
      final mid = occ.progressAt(DateTime(2026, 11, 3, 14, 47, 30));
      expect(mid, closeTo(0.5, 0.01));
    });
  });
}
