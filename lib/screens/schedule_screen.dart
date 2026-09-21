import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/lesson.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDay = 0;
  int _selectedWeek = 0;
  String _userGroup = '';
  bool _isLoading = true;

  static const List<String> _days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
  static const List<String> _weeks = ['Общая', 'Нечетная', 'Четная'];

  @override
  void initState() {
    super.initState();
    _loadUserGroup();
    _detectCurrentWeek();
  }

  void _detectCurrentWeek() {
    final now = DateTime.now();
    final startDate = DateTime(2026, 9, 1);
    final diff = now.difference(startDate).inDays;
    final weekNumber = (diff / 7).floor() + 1;

    if (weekNumber % 2 == 0) {
      _selectedWeek = 2;
    } else {
      _selectedWeek = 1;
    }
    print('📅 Текущая неделя: ${_weeks[_selectedWeek]} (№$weekNumber)');
  }

  Future<void> _loadUserGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _userGroup = 'Б-ПИГМУ-24';
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userGroup = (data['group'] as String?)?.trim() ?? 'Б-ПИГМУ-24';
          _isLoading = false;
        });
        print('✅ Группа загружена: "$_userGroup"');
      } else {
        setState(() {
          _userGroup = 'Б-ПИГМУ-24';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Ошибка загрузки группы: $e');
      setState(() {
        _userGroup = 'Б-ПИГМУ-24';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Расписание'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.primaryNavy,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_weeks.length, (i) {
                    final isSelected = i == _selectedWeek;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedWeek = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color:
                          isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                            isSelected ? Colors.white : Colors.white24,
                          ),
                        ),
                        child: Text(
                          _weeks[i],
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryNavy
                                : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              _DaySelector(
                days: _days,
                selected: _selectedDay,
                onSelect: (i) => setState(() => _selectedDay = i),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        // Загружаем только занятия этой группы
        stream: FirebaseFirestore.instance
            .collection('lessons')
            .where('group', isEqualTo: _userGroup)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('❌ Firestore ошибка: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          print('📊 Firestore вернул: ${docs.length} документов группы $_userGroup');

          // ФИЛЬТР ПО ДНЮ И НЕДЕЛЕ В DART
          final lessons = docs
              .map((doc) => Lesson.fromMap(
              doc.id, doc.data() as Map<String, dynamic>))
              .where((lesson) {
            final dayMatch = lesson.dayIndex == _selectedDay;
            final weekMatch = _selectedWeek == 0
                ? lesson.week == 0
                : (lesson.week == 0 ||
                lesson.week == _selectedWeek);

            // Логи для отладки
            if (dayMatch) {
              print('  📄 ${lesson.subject} | day=${lesson.dayIndex} | week=${lesson.week} | show=${dayMatch && weekMatch}');
            }

            return dayMatch && weekMatch;
          })
              .toList();

          print('📊 После фильтра (день=$_selectedDay, неделя=$_selectedWeek): ${lessons.length}');

          lessons.sort((a, b) => a.startTime.compareTo(b.startTime));

          if (lessons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'Занятий не найдено',
                    style: TextStyle(
                        fontSize: 16, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Группа: $_userGroup',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Неделя: ${_weeks[_selectedWeek]}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            itemBuilder: (context, i) =>
                _LessonCard(lesson: lessons[i]),
          );
        },
      ),
    );
  }
}

// --- DAY SELECTOR ---
class _DaySelector extends StatelessWidget {
  final List<String> days;
  final int selected;
  final ValueChanged<int> onSelect;

  const _DaySelector({
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryNavy,
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(days.length, (i) {
          final isSelected = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                days[i],
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryNavy : Colors.white60,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// --- LESSON CARD ---
class _LessonCard extends StatelessWidget {
  final Lesson lesson;

  const _LessonCard({required this.lesson});

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
      default:
        return lesson.type;
    }
  }

  Color get _typeColor {
    switch (lesson.type) {
      case 'лек':
      case 'лекц':
        return const Color(0xFF3D6FA3);
      case 'пр':
      case 'практ':
        return const Color(0xFF2E7D52);
      case 'лаб':
        return const Color(0xFF8A5A00);
      default:
        return AppTheme.textMuted;
    }
  }

  String get _weekLabel {
    switch (lesson.week) {
      case 0:
        return 'Общая';
      case 1:
        return 'Нечетная';
      case 2:
        return 'Четная';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekColor = lesson.week == 0
        ? Colors.grey[400]
        : (lesson.week == 1 ? Colors.blue[300] : Colors.orange[300]);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                lesson.startTime,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryNavy,
                ),
              ),
              Text(
                lesson.endTime,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Container(
            width: 2,
            height: 56,
            color: _typeColor.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lesson.subject,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    if (lesson.week != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: weekColor?.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: weekColor ?? Colors.grey,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          _weekLabel,
                          style: TextStyle(
                            fontSize: 9,
                            color: weekColor?.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.room_outlined,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      lesson.room,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.person_outline,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        lesson.teacher,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: _typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}