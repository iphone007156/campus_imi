import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/calendar_import_service.dart';
import '../theme/app_theme.dart';

class AdminCalendarImportScreen extends StatefulWidget {
  const AdminCalendarImportScreen({super.key});

  @override
  State<AdminCalendarImportScreen> createState() =>
      _AdminCalendarImportScreenState();
}

class _AdminCalendarImportScreenState extends State<AdminCalendarImportScreen> {
  bool _isLoading = false;
  String? _fileName;
  Uint8List? _fileBytes;

  Future<void> _pickFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        debugPrint('ℹ️ [IMPORT] Файл не выбран');
        return;
      }
      final f = picked.files.single;
      final bytes = f.bytes;
      if (bytes == null) {
        debugPrint('❌ [IMPORT] bytes == null для файла ${f.name}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось прочитать файл'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      debugPrint('🔍 [IMPORT] Файл выбран: ${f.name}, ${bytes.length} байт');
      setState(() {
        _fileName = f.name;
        _fileBytes = bytes;
      });
    } catch (e, st) {
      debugPrint('❌ [IMPORT] FilePicker error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора файла: $e')),
        );
      }
    }
  }

  Future<void> _import() async {
    if (_fileBytes == null) {
      debugPrint('⚠️ [IMPORT] Нажали «Импортировать» без файла');
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('🚀 [IMPORT] Старт импорта');

    try {
      final count =
      await CalendarImportService().importFromExcel(_fileBytes!);

      debugPrint('🎉 [IMPORT] Импортировано: $count');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Импортировано $count записей'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('❌ [IMPORT] Ошибка: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Импорт учебного плана')),
      backgroundColor: AppTheme.backgroundGray,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.accentBlue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Загрузите файл КУГ (xlsx). Будут импортированы данные '
                        'с листа "приложение" (сессии, практики, каникулы).',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickFile,
            icon: const Icon(Icons.upload_file),
            label: Text(_fileName ?? 'Выбрать .xlsx'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
          ),

          if (_fileBytes != null && !_isLoading) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _import,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Импортировать данные'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}