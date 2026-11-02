import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/excel_export_service.dart';

class AdminExportScreen extends StatefulWidget {
  const AdminExportScreen({super.key});

  @override
  State<AdminExportScreen> createState() => _AdminExportScreenState();
}

class _AdminExportScreenState extends State<AdminExportScreen> {
  // Что включать в файл
  bool _includeName = true;
  bool _includeGroup = true;
  bool _includePhone = false;
  bool _includeEmail = false;
  bool _includePoints = false;

  // Фильтр по ролям (по умолчанию - все студенты, т.е. пустой список)
  String _roleFilter = 'Все';
  final List<String> _roles = ['Все', 'Студент', 'Староста', 'Заместитель', 'Активист', 'Админ'];

  bool _isExporting = false;

  Future<void> _export() async {
    setState(() => _isExporting = true);

    try {
      // Определяем фильтр по ролям
      List<String> roleFilterList = [];
      if (_roleFilter == 'Староста') roleFilterList = ['head'];
      if (_roleFilter == 'Заместитель') roleFilterList = ['deputy'];
      if (_roleFilter == 'Активист') roleFilterList = ['activist'];
      if (_roleFilter == 'Админ') roleFilterList = ['admin'];
      if (_roleFilter == 'Студент') roleFilterList = []; // Студенты - это все, у кого нет других ролей

      final filePath = await ExcelExportService.exportUsers(
        includeName: _includeName,
        includeGroup: _includeGroup,
        includePhone: _includePhone,
        includeEmail: _includeEmail,
        includePoints: _includePoints,
        roleFilter: roleFilterList,
      );

      // Открываем окно "Поделиться"
      await ExcelExportService.shareFile(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Файл сформирован и отправлен'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Экспорт данных в Excel')),
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
                    'Выберите поля и роль для фильтрации. Файл .xlsx сохранится и вы сможете отправить его в Telegram или сохранить на телефон.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ✅ Фильтр по роли
          const Text('Кого выгрузить:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _roleFilter,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _roleFilter = v);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ✅ Какие поля включать
          const Text('Какие поля включить:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                CheckboxListTile(title: const Text('ФИО'), value: _includeName, onChanged: (v) => setState(() => _includeName = v!)),
                CheckboxListTile(title: const Text('Группа'), value: _includeGroup, onChanged: (v) => setState(() => _includeGroup = v!)),
                CheckboxListTile(title: const Text('Телефон'), value: _includePhone, onChanged: (v) => setState(() => _includePhone = v!)),
                CheckboxListTile(title: const Text('Email'), value: _includeEmail, onChanged: (v) => setState(() => _includeEmail = v!)),
                CheckboxListTile(title: const Text('Баллы ППОС'), value: _includePoints, onChanged: (v) => setState(() => _includePoints = v!)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _isExporting ? null : _export,
            icon: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.download),
            label: Text(_isExporting ? 'Формирование файла...' : 'Скачать .xlsx'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}