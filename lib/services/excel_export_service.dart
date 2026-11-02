import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class ExcelExportService {
  /// Экспорт списка пользователей в Excel
  /// Возвращает путь к файлу для шаринга
  static Future<String> exportUsers({
    required bool includeName,
    required bool includeGroup,
    required bool includePhone,
    required bool includeEmail,
    required bool includePoints,
    required List<String> roleFilter, // Например, ['head'] или []
    String? groupFilter, // Если нужно только по группе
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Студенты'];

    // Формируем заголовки
    final headers = <String>[];
    if (includeName) headers.add('ФИО');
    if (includeGroup) headers.add('Группа');
    if (includePhone) headers.add('Телефон');
    if (includeEmail) headers.add('Email');
    if (includePoints) headers.add('Баллы ППОС');

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.blueGrey100);
    }

    // Получаем пользователей из Firestore
    Query query = FirebaseFirestore.instance.collection('users');
    if (groupFilter != null && groupFilter.isNotEmpty) {
      query = query.where('group', isEqualTo: groupFilter);
    }
    final snapshot = await query.get();

    int rowIndex = 1;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Фильтр по ролям (если выбран)
      if (roleFilter.isNotEmpty) {
        final userRoles = (data['roles'] as List?)?.cast<String>() ?? [];
        final globalRole = data['role'] ?? 'student';

        bool hasRole = false;
        for (String r in roleFilter) {
          if (userRoles.contains(r) || globalRole == r) {
            hasRole = true;
            break;
          }
        }
        if (!hasRole) continue; // Пропускаем, если роль не совпала
      }

      int colIndex = 0;
      if (includeName) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
            .value = TextCellValue(data['name'] ?? '');
      }
      if (includeGroup) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
            .value = TextCellValue(data['group'] ?? '');
      }
      if (includePhone) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
            .value = TextCellValue(data['phone'] ?? '');
      }
      if (includeEmail) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
            .value = TextCellValue(data['email'] ?? '');
      }
      if (includePoints) {
        final points = int.tryParse(data['unionPoints']?.toString() ?? '0') ?? 0;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
            .value = IntCellValue(points);
      }

      rowIndex++;
    }

    // Авто-ширина колонок
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 25);
    }

    // Сохраняем файл
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'students_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return filePath;
  }

  /// Поделиться файлом через системное окно
  static Future<void> shareFile(String filePath) async {
    final file = XFile(filePath);
    await Share.shareXFiles([file], text: 'Экспорт студентов СВФУ Кампус');
  }
}