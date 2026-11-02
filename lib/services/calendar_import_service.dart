import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:excel/excel.dart';

class CalendarImportService {
  final _db = FirebaseFirestore.instance;

  /// Детерминированный ID — повторный импорт не создаёт дублей.
  String _docId(String group, int semester, String component, DateTime start) {
    final key = '$group|$semester|$component|${start.toIso8601String()}';
    return md5.convert(utf8.encode(key)).toString();
  }

  Future<int> importFromExcel(
      Uint8List bytes, {
        void Function(int done, int total)? onProgress,
      }) async {
    final excel = Excel.decodeBytes(bytes);

    // ---- 1. Ищем лист "приложение" ----
    String? targetSheet;
    for (var name in excel.tables.keys) {
      if (name.toLowerCase().contains('приложение')) {
        targetSheet = name;
        break;
      }
    }
    if (targetSheet == null) {
      throw Exception('Лист "приложение" не найден в файле');
    }

    final sheet = excel.tables[targetSheet]!;
    if (sheet.rows.isEmpty) return 0;

    // ---- 2. Парсим строки ----
    // Колонки (0-based):
    // 0 № | 1 учп | 2 Код | 3 Направление | 4 Профиль | 5 фгос | 6 уровень
    // 7 форма | 8 Кол-во | 9 Курс | 10 Группа | 11 Семестр
    // 12 Продолжительность | 13 Компонент | 14 Начало | 15 Конец
    const colGroup = 10;
    const colSemester = 11;
    const colDuration = 12;
    const colComponent = 13;
    const colStart = 14;
    const colEnd = 15;

    // Универсальное извлечение строки из ячейки.
    // Не зависит от конкретного класса CellValue (Text/Int/DateTime/...).
    String cellAt(List<Data?> row, int idx) {
      if (idx >= row.length) return '';
      final v = row[idx]?.value;
      if (v == null) return '';

      final asString = v.toString().trim();

      // DateTimeCellValue.toString() в excel 4.x обычно даёт ISO-подобную строку.
      final iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(asString);
      if (iso != null) {
        return '${iso.group(1)}-${iso.group(2)}-${iso.group(3)}';
      }

      // Иногда toString() выглядит как "DateTime(2026, 9, 1, 0, 0)".
      final dtLike = RegExp(r'DateTime\((\d{4}),\s*(\d{1,2}),\s*(\d{1,2})')
          .firstMatch(asString);
      if (dtLike != null) {
        final y = dtLike.group(1)!;
        final m = dtLike.group(2)!.padLeft(2, '0');
        final d = dtLike.group(3)!.padLeft(2, '0');
        return '$y-$m-$d';
      }

      return asString;
    }

    // "Тянущиеся" значения для объединённых ячеек.
    // Храним СЫРУЮ строку группы (возможно, с запятой), разбиваем позже.
    String currentGroupRaw = '';
    String currentSemesterStr = '';
    String currentDuration = '';

    final records = <_PlanRecord>[];

    // Строка 0 — заголовок, 1 — пустая, данные начинаются со 2-й.
    for (var i = 2; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;

      final rawGroup = cellAt(row, colGroup);
      if (rawGroup.isNotEmpty && rawGroup != 'nan' && rawGroup != 'null') {
        currentGroupRaw = rawGroup;
      }

      final rawSem = cellAt(row, colSemester);
      if (rawSem.isNotEmpty && rawSem != 'nan' && rawSem != 'null') {
        currentSemesterStr = rawSem;
      }

      final rawDur = cellAt(row, colDuration);
      if (rawDur.isNotEmpty && rawDur != 'nan' && rawDur != 'null') {
        currentDuration = rawDur;
      }

      final component = cellAt(row, colComponent);
      final startStr = cellAt(row, colStart);
      final endStr = cellAt(row, colEnd);

      if (component.isEmpty) continue;
      if (startStr.isEmpty && endStr.isEmpty) continue;
      if (currentGroupRaw.isEmpty) continue;

      final semester = _parseSemester(currentSemesterStr);
      final start = _parseDate(startStr);
      final end = _parseDate(endStr) ?? start;
      if (start == null || end == null) continue;

      // ✅ РАЗБИВАЕМ ГРУППУ ПО ЗАПЯТОЙ и создаём ОТДЕЛЬНУЮ запись для каждой.
      final groups = _splitGroups(currentGroupRaw);

      for (final g in groups) {
        records.add(_PlanRecord(
          group: g,
          semester: semester,
          component: component,
          start: start,
          end: end,
          duration: currentDuration,
        ));
      }
    }

    if (records.isEmpty) return 0;

    // ---- 3. Удаляем старые записи ТОЛЬКО для затронутых групп ----
    final affectedGroups = records.map((r) => r.group).toSet();
    for (final g in affectedGroups) {
      final old = await _db
          .collection('calendar_plan')
          .where('group', isEqualTo: g)
          .get();
      for (var i = 0; i < old.docs.length; i += 400) {
        final batch = _db.batch();
        final slice = old.docs.skip(i).take(400);
        for (final doc in slice) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }

    // ---- 4. Пишем новыми батчами по 400 ----
    var done = 0;
    for (var i = 0; i < records.length; i += 400) {
      final chunk = records.sublist(i, (i + 400).clamp(0, records.length));
      final batch = _db.batch();
      for (final r in chunk) {
        final id = _docId(r.group, r.semester, r.component, r.start);
        batch.set(
          _db.collection('calendar_plan').doc(id),
          {
            'group': r.group,
            'semester': r.semester,
            'component': r.component,
            'start': Timestamp.fromDate(r.start),
            'end': Timestamp.fromDate(r.end),
            'duration': r.duration,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
        done++;
        onProgress?.call(done, records.length);
      }
      await batch.commit();
    }

    return records.length;
  }

  /// ✅ РАЗБИВАЕМ ГРУППУ ПО ЗАПЯТОЙ И НОРМАЛИЗУЕМ КАЖДУЮ ЧАСТЬ.
  /// "ИМИ-Б-ИВТ-26-1, ИМИ-Б-ИВТ-26-2" -> ["Б-ИВТ-26-1", "Б-ИВТ-26-2"]
  List<String> _splitGroups(String raw) {
    final parts = raw.split(RegExp(r'[,;]'));
    final result = <String>[];
    for (final p in parts) {
      final normalized = _normalizeGroup(p);
      if (normalized.isNotEmpty && !result.contains(normalized)) {
        result.add(normalized);
      }
    }
    return result;
  }

  /// Нормализация группы: убираем префикс "ИМИ-" / "ИМИ ".
  /// "ИМИ-Б-М-26" -> "Б-М-26"
  String _normalizeGroup(String raw) {
    return raw
        .replaceAll(RegExp(r'^ИМИ[-\s]+'), '')
        .replaceAll(RegExp(r'^ИМИ'), '')
        .trim();
  }

  int _parseSemester(String raw) {
    final m = RegExp(r'(\d+)').firstMatch(raw);
    return int.tryParse(m?.group(1) ?? '') ?? 1;
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final s = raw.trim();

    // ISO: 2026-09-01 00:00:00
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
      final d = DateTime.tryParse(s.split(' ').first);
      if (d != null) return DateTime(d.year, d.month, d.day);
    }

    // DD.MM.YYYY
    final dot = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})').firstMatch(s);
    if (dot != null) {
      return DateTime(
        int.parse(dot.group(3)!),
        int.parse(dot.group(2)!),
        int.parse(dot.group(1)!),
      );
    }

    return null;
  }
}

class _PlanRecord {
  final String group;
  final int semester;
  final String component;
  final DateTime start;
  final DateTime end;
  final String duration;

  _PlanRecord({
    required this.group,
    required this.semester,
    required this.component,
    required this.start,
    required this.end,
    required this.duration,
  });
}