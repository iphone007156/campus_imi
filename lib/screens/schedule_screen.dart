import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../models/lesson.dart';
import '../services/schedule_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/lesson_widgets.dart';

class ScheduleScreen extends StatefulWidget {
  /// true — экран внутри нижней навигации (без стрелки «назад»).
  final bool embedded;
  const ScheduleScreen({super.key, this.embedded = false});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const List<String> _dayNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ'];

  int _selectedDay = 0;
  int _selectedWeek = 0; // 0 — текущая, 1 — следующая
  String _userGroup = '';
  bool _loading = true;
  bool _loadFailed = false;
  List<DateTime> _oddWeeks = [];
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _pickInitialDay();
    _loadData();
    // Раз в минуту обновляем подсветку «Сейчас».
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Открываем сегодняшний день; в воскресенье показываем понедельник следующей недели.
  void _pickInitialDay() {
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday) {
      _selectedWeek = 1;
      _selectedDay = 0;
    } else {
      _selectedWeek = 0;
      _selectedDay = now.weekday - 1;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      await initializeDateFormatting('ru_RU', null);
      final user = FirebaseAuth.instance.currentUser;
      String group = '';
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        group = ((doc.data()?['group'] as String?) ?? '').trim();
      }
      final odd = await ScheduleService.loadOddWeeks();
      if (!mounted) return;
      setState(() {
        _userGroup = group;
        _oddWeeks = odd;
        _stream = group.isEmpty ? null : _buildStream(group);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки расписания: $e');
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream(String group) {
    return FirebaseFirestore.instance
        .collection('lessons')
        .where('group', isEqualTo: group)
        .snapshots();
  }

  List<DateTime> _weekDates() {
    final monday = ScheduleService.mondayOf(DateTime.now());
    final start =
    DateTime(monday.year, monday.month, monday.day + _selectedWeek * 7);
    return List.generate(
        6, (i) => DateTime(start.year, start.month, start.day + i));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.appBarTheme.backgroundColor ?? AppTheme.primaryNavy;
    final fg = theme.appBarTheme.foregroundColor ?? Colors.white;
    return Container(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              if (!widget.embedded)
                IconButton(
                  icon: Icon(Icons.arrow_back, color: fg),
                  tooltip: 'Назад',
                  onPressed: () => Navigator.pop(context),
                )
              else
                const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Расписание',
                      style: TextStyle(
                        color: fg,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_userGroup.isNotEmpty)
                      Text(
                        'Группа $_userGroup',
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadFailed) return AppErrorState(onRetry: _loadData);
    if (_userGroup.isEmpty || _stream == null) {
      return const AppEmptyState(
        icon: Icons.groups_outlined,
        title: 'Группа не указана',
        message: 'Укажите группу в профиле, и здесь появится расписание',
      );
    }

    final dates = _weekDates();
    final weekNum = ScheduleService.weekNumber(dates.first, _oddWeeks);
    final rangeFmt = DateFormat('d MMMM', 'ru_RU');
    final rangeText =
        '${DateFormat('d', 'ru_RU').format(dates.first)}–${rangeFmt.format(dates.last)}'
        ' · ${weekNum == 1 ? 'нечётная' : 'чётная'} неделя';
    final selectedDate = dates[_selectedDay.clamp(0, dates.length - 1)];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: AppSegmented(
            labels: const ['Эта неделя', 'Следующая'],
            index: _selectedWeek,
            onChanged: (i) => setState(() => _selectedWeek = i),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              rangeText,
              style: TextStyle(fontSize: 12, color: appMutedColor(context)),
            ),
          ),
        ),
        _buildDayStrip(context, dates),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              children: [
                AppBadge('Лекция', tone: AppTone.accent),
                AppBadge('Практика', tone: AppTone.success),
                AppBadge('Лабораторная', tone: AppTone.warning),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return AppErrorState(
                  onRetry: () => setState(() => _stream = _buildStream(_userGroup)),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snapshot.data!.docs
                  .map((d) => Lesson.fromMap(d.id, d.data()))
                  .toList();
              final lessons =
              ScheduleService.lessonsForDate(all, selectedDate, _oddWeeks);

              if (lessons.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.free_breakfast_outlined,
                  title: 'Пар нет',
                  message: 'Можно отдохнуть',
                );
              }

              final now = DateTime.now();
              final isToday = ScheduleService.dateOnly(selectedDate) ==
                  ScheduleService.dateOnly(now);

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: lessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final lesson = lessons[i];
                  bool isNow = false;
                  bool isPast = false;
                  if (isToday) {
                    final occ = ScheduleService.occurrenceFor(lesson, selectedDate);
                    if (occ != null) {
                      isNow = occ.isActiveAt(now);
                      isPast = !isNow && occ.end.isBefore(now);
                    }
                  }
                  return LessonTile(lesson: lesson, isNow: isNow, isPast: isPast);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayStrip(BuildContext context, List<DateTime> dates) {
    final dark = appIsDark(context);
    final today = ScheduleService.dateOnly(DateTime.now());
    final selectedBg = dark ? AppTheme.accentOnDark : AppTheme.primaryNavy;
    final selectedFg = dark ? const Color(0xFF0B1230) : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: List.generate(dates.length, (i) {
          final selected = i == _selectedDay;
          final isToday = ScheduleService.dateOnly(dates[i]) == today;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              label: '${_dayNames[i]}, ${dates[i].day}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selectedDay = i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  constraints: const BoxConstraints(minHeight: 56),
                  decoration: BoxDecoration(
                    color: selected ? selectedBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayNames[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected ? selectedFg : appMutedColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dates[i].day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? selectedFg
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday
                              ? (selected ? selectedFg : appAccentColor(context))
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
