import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/lesson.dart';
import '../services/firestore_service.dart';
import 'add_schedule_screen.dart';

class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({super.key});

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedDay = 0;
  String _selectedGroup = 'Б-ПИГМУ-24';

  static const List<String> _days = [
    'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб',
  ];

  static const List<String> _groups = [
    'Б-ПИГМУ-24',
    'Б-ПИЭ-24',
    'Б-ИВТ-24-1',
    'Б-ИВТ-24-2',
    'Б-ФИИТ-24',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление расписанием'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Добавить занятие',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddScheduleScreen(),
                ),
              );
              if (result == true && mounted) setState(() {});
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          // Выбор группы
          Container(
            color: AppTheme.cardWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.groups, color: AppTheme.accentBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGroup,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: _groups.map((g) {
                        return DropdownMenuItem(value: g, child: Text(g));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedGroup = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Переключатель дней
          Container(
            color: AppTheme.primaryNavy,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_days.length, (i) {
                final isSelected = i == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _days[i],
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryNavy
                            : Colors.white60,
                        fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Список занятий
          Expanded(
            child: StreamBuilder<List<Lesson>>(
              stream: _firestoreService.getLessons(_selectedDay),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }

                // Фильтруем по группе
                final allLessons = snapshot.data ?? [];
                final lessons = allLessons
                    .where((l) => l.group == _selectedGroup)
                    .toList();

                if (lessons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 16),
                        const Text(
                          'Занятий нет',
                          style: TextStyle(
                              fontSize: 18, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Группа: $_selectedGroup',
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Нажмите + чтобы добавить',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lessons.length,
                  itemBuilder: (context, i) => _AdminLessonCard(
                    lesson: lessons[i],
                    onEdit: () => _openEditor(lessons[i]),
                    onDelete: () => _confirmDelete(lessons[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(Lesson lesson) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddScheduleScreen(lesson: lesson),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _confirmDelete(Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить занятие?'),
        content: Text(
          '${lesson.subject}\n'
              '${lesson.time}\n'
              '${lesson.teacher}\n'
              'Группа: ${lesson.group}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.deleteLesson(lesson.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Занятие удалено'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _AdminLessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminLessonCard({
    required this.lesson,
    required this.onEdit,
    required this.onDelete,
  });

  String get _typeLabel {
    switch (lesson.type) {
      case 'лек':
      case 'лекц':
        return 'Лекция';
      case 'пр':
      case 'практ':
        return 'Практика';
      case 'лаб':
        return 'Лабораторная';
      case 'сем':
        return 'Семинар';
      default:
        return lesson.type;
    }
  }

  String get _weekLabel {
    switch (lesson.week) {
      case 0:
        return 'Общая';
      case 1:
        return 'Нечётная';
      case 2:
        return 'Чётная';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lesson.time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (lesson.week != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _weekLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lesson.subject,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lesson.teacher,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
              const Icon(Icons.room_outlined,
                  size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                lesson.room,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _typeLabel,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.accentBlue),
                ),
              ),
              const Spacer(),
              // ✅ Кнопка редактирования
              IconButton(
                icon: const Icon(Icons.edit,
                    size: 20, color: AppTheme.accentBlue),
                onPressed: onEdit,
                tooltip: 'Редактировать',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              // ✅ Кнопка удаления
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Удалить',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}