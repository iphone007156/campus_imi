import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminImportCalendarScreen extends StatefulWidget {
  const AdminImportCalendarScreen({super.key});

  @override
  State<AdminImportCalendarScreen> createState() => _AdminImportCalendarScreenState();
}

class _AdminImportCalendarScreenState extends State<AdminImportCalendarScreen> {
  bool _isLoading = false;

  Future<void> _pickAndUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) return;
      setState(() => _isLoading = true);

      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      List<String> oddWeeks = [];

      for (var table in excel.tables.keys) {
        for (var row in excel.tables[table]!.rows) {
          if (row.isEmpty || row[0]?.value == null) continue;

          String cellValue = row[0]?.value.toString() ?? '';
          if (cellValue.contains('Нечетные') || cellValue.trim().isEmpty) continue;

          // Ищем даты формата DD.MM.YY или DD.MM.YYYY
          RegExp dateRegex = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{2,4})');
          var match = dateRegex.firstMatch(cellValue);

          if (match != null) {
            String day = match.group(1)!.padLeft(2, '0');
            String month = match.group(2)!.padLeft(2, '0');
            String year = match.group(3)!;

            if (year.length == 2) year = '20$year';
            oddWeeks.add('$year-$month-$day');
          }
        }
      }

      if (oddWeeks.isNotEmpty) {
        // Очищаем старые записи, чтобы не копились
        final oldDocs = await FirebaseFirestore.instance.collection('semester_calendar').get();
        for (var doc in oldDocs.docs) {
          await doc.reference.delete();
        }

        // Сохраняем новый график
        await FirebaseFirestore.instance.collection('semester_calendar').add({
          'semester': '2026-2027_1',
          'odd_weeks': oddWeeks,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('✅ График загружен! Найдено недель: ${oddWeeks.length}'),
                backgroundColor: Colors.green
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('❌ Даты не найдены. Проверьте файл.'),
                backgroundColor: Colors.orange
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Импорт графика недель')),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.date_range, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Загрузите Excel-файл с графиком учебного процесса. Приложение автоматически найдет все даты нечетных недель и сохранит их в базу.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _pickAndUpload,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.upload_file),
                label: const Text('Выбрать файл .xlsx'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}