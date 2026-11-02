import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/excel_schedule_parser.dart';
import '../services/schedule_import_service.dart';
import '../theme/app_theme.dart';
import '../models/department_model.dart';

class AdminImportScheduleScreen extends StatefulWidget {
  const AdminImportScheduleScreen({super.key});

  @override
  State<AdminImportScheduleScreen> createState() =>
      _AdminImportScheduleScreenState();
}

class _AdminImportScheduleScreenState
    extends State<AdminImportScheduleScreen> {
  bool _parsing = false;
  bool _importing = false;
  ExcelParseResult? _result;
  String? _fileName;
  int _done = 0;
  int _total = 0;

  String? _selectedDeptId;

  static const _daysShort = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ'];

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (picked == null || picked.files.single.bytes == null) return;

    setState(() {
      _parsing = true;
      _result = null;
      _fileName = picked.files.single.name;
    });

    try {
      final bytes = picked.files.single.bytes!;
      final result = await Future.microtask(
            () => ExcelScheduleParser.parse(Uint8List.fromList(bytes)),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _parsing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _parsing = false);
      _snack('Ошибка чтения файла: $e', error: true);
    }
  }

  Future<void> _import() async {
    final r = _result;
    if (r == null || r.lessons.isEmpty) return;
    if (_selectedDeptId == null) {
      _snack('Пожалуйста, выберите подразделение для этих групп', error: true);
      return;
    }

    setState(() {
      _importing = true;
      _done = 0;
      _total = r.lessons.length;
    });

    try {
      final count = await ScheduleImportService().importLessons(
        r.lessons,
        onProgress: (d, t) {
          if (mounted) setState(() {
            _done = d;
            _total = t;
          });
        },
      );

      final uniqueGroups = r.lessons.map((l) => l.group).toSet();
      for (String groupName in uniqueGroups) {
        final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupName);
        final existingDoc = await groupRef.get();
        if (existingDoc.exists && existingDoc.data()?['departmentId'] != null) {
          continue;
        }
        await groupRef.set({
          'name': groupName,
          'departmentId': _selectedDeptId,
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      _snack('Импортировано $count пар. Группы привязаны к подразделению.');
      setState(() {
        _importing = false;
        _result = null;
        _fileName = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      _snack('Ошибка импорта: $e', error: true);
    }
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? Colors.red : AppTheme.primaryNavy,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Импорт расписания из Excel')),
      backgroundColor: AppTheme.backgroundGray,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('1. К какому подразделению относятся эти группы?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('departments').orderBy('shortName').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();

              final depts = snapshot.data!.docs.map((d) => Department.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();

              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Подразделение',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.cardWhite,
                ),
                value: _selectedDeptId,
                isExpanded: true, // ✅ Важно: растягиваем на всю ширину
                items: depts.map((d) => DropdownMenuItem(
                  value: d.id,
                  // ✅ Ограничиваем текст одной строкой и добавляем троеточие
                  child: Text(
                    '${d.shortName} (${d.name})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _selectedDeptId = v),
              );
            },
          ),
          const SizedBox(height: 24),

          const Text('2. Выберите файл .xlsx', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _parsing || _importing ? null : _pickFile,
            icon: const Icon(Icons.upload_file),
            label: Text(_fileName ?? 'Выбрать файл'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
          ),

          if (_parsing)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (_result != null) ...[
            const SizedBox(height: 16),
            _buildSummary(_result!),
            const SizedBox(height: 12),
            if (_result!.lessons.isNotEmpty) ...[
              if (_importing)
                LinearProgressIndicator(
                  value: _total == 0 ? null : _done / _total,
                ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _importing ? null : _import,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(_importing
                    ? 'Импорт $_done/$_total…'
                    : 'Импортировать ${_result!.lessons.length} пар'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(ExcelParseResult r) {
    final groups = r.lessons.map((l) => l.group).toSet().toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Распознано пар: ${r.lessons.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Группы (${groups.length}): ${groups.join(", ")}',
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500),
            ),

            if (r.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ошибок: ${r.errors.length}',
                style: const TextStyle(color: Colors.red),
              ),
              ...r.errors.take(8).map((e) => Text(
                '• $e',
                style: const TextStyle(fontSize: 12),
              )),
              if (r.errors.length > 8)
                Text(
                  '… и ещё ${r.errors.length - 8}',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Первые 10 пар:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...r.lessons.take(10).map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '${l.group} · ${_daysShort[l.dayIndex]} · '
                    '${l.week == 0 ? "кажд." : l.week == 1 ? "нечёт." : "чёт."} · '
                    '${l.time} · ${l.subject}',
                style: const TextStyle(fontSize: 12),
              ),
            )),
            if (r.lessons.length > 10)
              Text(
                '… и ещё ${r.lessons.length - 10}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}