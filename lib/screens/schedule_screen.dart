import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../theme/app_theme.dart';
import '../models/lesson.dart';
import '../services/notification_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDay = 0;
  int _selectedWeek = 0; // 0 = текущая, 1 = следующая
  String _userGroup = '';
  bool _isLoading = true;

  // Список нечетных недель (загружается из Firebase)
  List<DateTime> _oddWeeks = [];

  static const List<String> _days = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ'];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU', null);
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadUserGroup();
    await _loadCalendar();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _userGroup = 'Б-ПИГМУ-24';
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        _userGroup = (doc.data()?['group'] as String?)?.trim() ?? 'Б-ПИГМУ-24';
      } else {
        _userGroup = 'Б-ПИГМУ-24';
      }
    } catch (e) {
      _userGroup = 'Б-ПИГМУ-24';
    }
  }

  // ✅ Загрузка графика из Firebase
  Future<void> _loadCalendar() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('semester_calendar')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final List<dynamic> datesStr = data['odd_weeks'] ?? [];

        _oddWeeks = datesStr.map((str) {
          final parts = str.toString().split('-');
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }).toList();
      } else {
        _setDefaultCalendar();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки календаря: $e');
      _setDefaultCalendar();
    }
  }

  void _setDefaultCalendar() {
    _oddWeeks = [
      DateTime(2026, 8, 31), DateTime(2026, 9, 14), DateTime(2026, 9, 28),
      DateTime(2026, 10, 12), DateTime(2026, 10, 26), DateTime(2026, 11, 9),
      DateTime(2026, 11, 23), DateTime(2026, 12, 7), DateTime(2026, 12, 21),
    ];
  }

  DateTime _getMondayForSelectedWeek() {
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    return currentMonday.add(Duration(days: _selectedWeek * 7));
  }

  int _getWeekNumber(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    for (final startDate in _oddWeeks) {
      final endDate = startDate.add(const Duration(days: 6));
      if ((targetDate.isAtSameMomentAs(startDate) || targetDate.isAfter(startDate)) &&
          targetDate.isBefore(endDate.add(const Duration(days: 1)))) {
        return 1; // Нечетная
      }
    }
    return 2; // Четная
  }

  List<DateTime> _getDatesForWeek() {
    final monday = _getMondayForSelectedWeek();
    return List.generate(6, (index) => monday.add(Duration(days: index)));
  }

  String _formatDayHeader(DateTime date) {
    final formatter = DateFormat('EEEE, d MMMM', 'ru_RU');
    String formatted = formatter.format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dates = _getDatesForWeek();
    final currentMonth = DateFormat('MMMM', 'ru_RU').format(dates.first);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedDate = dates.first;
    final weekNum = _getWeekNumber(selectedDate);
    final isEven = weekNum == 2;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 16, right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Theme.of(context).cardColor, Theme.of(context).cardColor]
                    : [const Color(0xFF3D6FA3), AppTheme.primaryNavy],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new,
                          color: isDark ? Colors.white : Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('Расписание', style: TextStyle(color: isDark ? Colors.white : Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('группа $_userGroup', style: TextStyle(color: isDark ? Colors.white70 : Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedWeek = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedWeek == 0 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text('Эта неделя', style: TextStyle(color: _selectedWeek == 0 ? AppTheme.primaryNavy : Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedWeek = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedWeek == 1 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text('Следующая', style: TextStyle(color: _selectedWeek == 1 ? AppTheme.primaryNavy : Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${dates.first.day}–${dates.last.day} $currentMonth · ${isEven ? "четная неделя" : "нечетная неделя"}',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_days.length, (i) {
                final isSelected = i == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = i),
                  child: Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(_days[i], style: TextStyle(color: isSelected ? Colors.white60 : Theme.of(context).textTheme.bodySmall?.color, fontSize: 11, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(dates[i].day.toString(), style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color, fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(_formatDayHeader(dates[_selectedDay]), style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('lessons').where('group', isEqualTo: _userGroup).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Ошибка: ${snapshot.error}'));

                final docs = snapshot.data?.docs ?? [];
                final lessons = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return Lesson.fromMap(doc.id, data);
                }).where((lesson) {
                  return lesson.dayIndex == _selectedDay && (lesson.week == 0 || lesson.week == weekNum);
                }).toList();

                lessons.sort((a, b) {
                  String timeA = a.time.split('-')[0].trim();
                  String timeB = b.time.split('-')[0].trim();
                  int hourA = int.tryParse(timeA.split(':')[0]) ?? 0;
                  int minA = int.tryParse(timeA.split(':')[1]) ?? 0;
                  int hourB = int.tryParse(timeB.split(':')[0]) ?? 0;
                  int minB = int.tryParse(timeB.split(':')[1]) ?? 0;
                  if (hourA != hourB) return hourA.compareTo(hourB);
                  return minA.compareTo(minB);
                });

                if (lessons.isNotEmpty) {
                  NotificationService.scheduleLessonReminders(lessons);
                }

                if (lessons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.free_breakfast_outlined, size: 64, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('Пар нет', style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodySmall?.color)),
                        const SizedBox(height: 8),
                        Text('Можно отдохнуть!', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: lessons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _LessonCard(lesson: lessons[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  const _LessonCard({required this.lesson});

  Color get _typeColor {
    switch (lesson.type.toLowerCase()) {
      case 'лек': case 'лекц': return const Color(0xFF3D6FA3);
      case 'пр': case 'практ': return const Color(0xFF2E7D52);
      case 'лаб': return const Color(0xFF8A5A00);
      case 'сем': return const Color(0xFF7E3FBF);
      default: return AppTheme.textMuted;
    }
  }

  String get _typeLabel {
    switch (lesson.type.toLowerCase()) {
      case 'лек': case 'лекц': return 'Лекция';
      case 'пр': case 'практ': return 'Практика';
      case 'лаб': return 'Лабораторная';
      case 'сем': return 'Семинар';
      default: return lesson.type;
    }
  }

  List<String> get _times => lesson.time.split('-');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: _typeColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_times.isNotEmpty ? _times[0].trim() : '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(width: 20, height: 1, color: Colors.white54),
                  const SizedBox(height: 4),
                  Text(_times.length > 1 ? _times[1].trim() : '', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: _typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(_typeLabel, style: TextStyle(fontSize: 10, color: _typeColor, fontWeight: FontWeight.bold)),
                        ),
                        if (lesson.week != 0) ...[
                          const SizedBox(width: 6),
                          Text(lesson.week == 1 ? "нечет." : "чет.", style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold))
                        ]
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(lesson.subject, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Expanded(child: Text(lesson.teacher, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text('Кабинет: ${lesson.room}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}