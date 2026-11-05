import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/lesson.dart';
import '../services/schedule_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/user_avatar.dart';
import 'gradebook_screen.dart';
import 'indoor_map_screen.dart';
import 'news_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';
import 'tasks_screen.dart';
import 'union_home_screen.dart';

/// Оболочка студента: нижняя навигация из пяти вкладок.
/// Главная · Расписание · Карта · Новости · Профиль.
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _index = 0;
  final Set<int> _visited = {0};

  String _userName = '';
  String _userGroup = '';
  String _userInstitute = '';
  bool _isLoading = true;

  List<Lesson> _lessons = [];
  List<DateTime> _oddWeeks = [];
  String _subscribedGroup = '';
  bool _lastNotificationsEnabled = SettingsService.instance.notificationsEnabled;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _lessonsSub;

  @override
  void initState() {
    super.initState();
    SettingsService.instance.addListener(_onSettingsChanged);
    _listenToUserData();
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChanged);
    _userSub?.cancel();
    _lessonsSub?.cancel();
    super.dispose();
  }

  void _onSettingsChanged() {
    final enabled = SettingsService.instance.notificationsEnabled;
    if (enabled != _lastNotificationsEnabled) {
      _lastNotificationsEnabled = enabled;
      _rescheduleReminders();
    }
  }

  void _listenToUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      final data = snapshot.data();
      if (data == null) {
        setState(() => _isLoading = false);
        return;
      }
      final group = ((data['group'] as String?) ?? '').trim();
      setState(() {
        _userName = ((data['name'] as String?) ?? '').trim();
        _userGroup = group;
        _userInstitute = ((data['institute'] as String?) ?? '').trim();
        _isLoading = false;
      });
      if (group != _subscribedGroup) _subscribeLessons(group);
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _subscribeLessons(String group) {
    _subscribedGroup = group;
    _lessonsSub?.cancel();
    _lessonsSub = null;
    if (group.isEmpty) {
      setState(() => _lessons = []);
      _rescheduleReminders();
      return;
    }
    _lessonsSub = FirebaseFirestore.instance
        .collection('lessons')
        .where('group', isEqualTo: group)
        .snapshots()
        .listen((snap) async {
      final lessons =
      snap.docs.map((d) => Lesson.fromMap(d.id, d.data())).toList();
      final odd = await ScheduleService.loadOddWeeks();
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _oddWeeks = odd;
      });
      _rescheduleReminders();
    }, onError: (e) => debugPrint('Ошибка подписки на пары: $e'));
  }

  void _rescheduleReminders() {
    ScheduleService.rescheduleReminders(_lessons, _oddWeeks).catchError((e) {
      debugPrint('Ошибка планирования напоминаний: $e');
    });
  }

  Widget _buildTab(int i) {
    if (!_visited.contains(i)) return const SizedBox.shrink();
    switch (i) {
      case 0:
        return _HomeTab(
          userName: _userName,
          userGroup: _userGroup,
          userInstitute: _userInstitute,
          isLoading: _isLoading,
          lessons: _lessons,
          oddWeeks: _oddWeeks,
          onOpenProfile: () => _selectTab(4),
        );
      case 1:
        return const ScheduleScreen(embedded: true);
      case 2:
        return const IndoorMapScreen();
      case 3:
        return const NewsScreen(embedded: true);
      default:
        return const ProfileScreen(embedded: true);
    }
  }

  void _selectTab(int i) {
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final langCode = SettingsService.instance.locale.languageCode;
        String t(String key) => AppStrings.t(key, langCode);
        final homeLabel = langCode == 'en' ? 'Home' : 'Главная';

        return PopScope(
          canPop: _index == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _selectTab(0);
          },
          child: Scaffold(
            body: IndexedStack(
              index: _index,
              children: List.generate(5, _buildTab),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _selectTab,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: homeLabel,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_today_outlined),
                  selectedIcon: const Icon(Icons.calendar_today),
                  label: t('schedule'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.map_outlined),
                  selectedIcon: const Icon(Icons.map),
                  label: t('map'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.newspaper_outlined),
                  selectedIcon: const Icon(Icons.newspaper),
                  label: t('news'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: t('profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ВКЛАДКА «ГЛАВНАЯ»: «Сейчас / дальше» и быстрые действия
// ═══════════════════════════════════════════════════════════
class _HomeTab extends StatefulWidget {
  final String userName;
  final String userGroup;
  final String userInstitute;
  final bool isLoading;
  final List<Lesson> lessons;
  final List<DateTime> oddWeeks;
  final VoidCallback onOpenProfile;

  const _HomeTab({
    required this.userName,
    required this.userGroup,
    required this.userInstitute,
    required this.isLoading,
    required this.lessons,
    required this.oddWeeks,
    required this.onOpenProfile,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Timer? _ticker;
  bool _dateReady = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU', null).then((_) {
      if (mounted) setState(() => _dateReady = true);
    });
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _firstName() {
    final parts = widget.userName.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    // В профиле имя хранится как «Фамилия Имя Отчество».
    return parts.length >= 2 ? parts[1] : parts[0];
  }

  String _greeting(String langCode) {
    final h = DateTime.now().hour;
    if (langCode == 'en') {
      if (h < 12) return 'Good morning';
      if (h < 18) return 'Good afternoon';
      return 'Good evening';
    }
    if (h < 6) return 'Доброй ночи';
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  String _dayLabel(DateTime date) {
    final today = ScheduleService.dateOnly(DateTime.now());
    final d = ScheduleService.dateOnly(date);
    final diff = d.difference(today).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Завтра';
    if (_dateReady) {
      final s = DateFormat('EEEE, d MMMM', 'ru_RU').format(date);
      return s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
    }
    return '${date.day}.${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final langCode = SettingsService.instance.locale.languageCode;
    String t(String key) => AppStrings.t(key, langCode);

    final now = DateTime.now();
    final list = ScheduleService.occurrences(widget.lessons, now, widget.oddWeeks, days: 14);
    final current = ScheduleService.current(list, now);
    final next = ScheduleService.next(list, now);

    return Column(
      children: [
        _buildHeader(context, langCode),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (widget.userGroup.isEmpty && !widget.isLoading)
                _buildNoGroupCard(context)
              else if (current != null) ...[
                _buildLessonCard(context, current, now, isCurrent: true),
                if (next != null) ...[
                  const SizedBox(height: 10),
                  _buildNextRow(context, next),
                ],
              ] else if (next != null)
                _buildLessonCard(context, next, now, isCurrent: false)
              else
                _buildNoLessonsCard(context),
              AppSectionLabel(t('services')),
              _buildQuickActions(context, t),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String langCode) {
    final theme = Theme.of(context);
    final bg = theme.appBarTheme.backgroundColor ?? AppTheme.primaryNavy;
    final fg = theme.appBarTheme.foregroundColor ?? Colors.white;
    String dateText = '';
    if (_dateReady) {
      final s = DateFormat('EEEE, d MMMM', 'ru_RU').format(DateTime.now());
      dateText = s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
    }
    final first = _firstName();
    final greeting = widget.isLoading
        ? _greeting(langCode)
        : (first.isEmpty ? _greeting(langCode) : '${_greeting(langCode)}, $first');

    return Container(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onOpenProfile,
                child: UserAvatar(
                  userId: FirebaseAuth.instance.currentUser?.uid,
                  size: 48,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  icon: Icons.person,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dateText.isNotEmpty)
                      Text(
                        dateText,
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      greeting,
                      style: TextStyle(
                        color: fg,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.userGroup.isNotEmpty)
                      Text(
                        widget.userGroup,
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: fg),
                tooltip: 'Настройки',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonCard(
      BuildContext context,
      LessonOccurrence o,
      DateTime now, {
        required bool isCurrent,
      }) {
    final lesson = o.lesson;
    final endFmt = DateFormat('HH:mm');
    final startFmt = DateFormat('HH:mm');
    final muted = appMutedColor(context);

    final details = <String>[
      if (lesson.teacher.isNotEmpty) lesson.teacher,
      if (lesson.room.isNotEmpty) 'кабинет ${lesson.room}',
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppBadge(
                isCurrent ? 'Идёт сейчас' : 'Дальше · ${_dayLabel(o.start)}',
                tone: isCurrent ? AppTone.success : AppTone.accent,
              ),
              Text(
                isCurrent
                    ? 'до ${endFmt.format(o.end)}'
                    : '${startFmt.format(o.start)}–${endFmt.format(o.end)}',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lesson.subject,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(details, style: TextStyle(fontSize: 13, color: muted)),
          ],
          if (isCurrent) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: o.progressAt(now),
                minHeight: 6,
                backgroundColor: appAccentSoftColor(context),
                valueColor: AlwaysStoppedAnimation<Color>(appAccentColor(context)),
              ),
            ),
          ],
          if (lesson.room.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => IndoorMapScreen.openForRoom(context, lesson.room),
                icon: const Icon(Icons.alt_route, size: 18),
                label: const Text('Показать на карте'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextRow(BuildContext context, LessonOccurrence o) {
    final fmt = DateFormat('HH:mm');
    final lesson = o.lesson;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: () => IndoorMapScreen.openForRoom(context, lesson.room),
      child: Row(
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: appAccentSoftColor(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              fmt.format(o.start),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: appAccentColor(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Дальше: ${lesson.subject}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  lesson.room.isEmpty ? _dayLabel(o.start) : 'кабинет ${lesson.room} · ${_dayLabel(o.start)}',
                  style: TextStyle(fontSize: 12, color: appMutedColor(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: appMutedColor(context)),
        ],
      ),
    );
  }

  Widget _buildNoGroupCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Укажите группу',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'После этого здесь появятся ближайшие пары',
            style: TextStyle(fontSize: 13, color: appMutedColor(context)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: widget.onOpenProfile,
            child: const Text('Открыть профиль'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLessonsCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const AppIconBox(Icons.free_breakfast_outlined, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ближайших пар нет',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Можно отдохнуть',
                  style: TextStyle(fontSize: 13, color: appMutedColor(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, String Function(String) t) {
    final items = <_QuickAction>[
      _QuickAction(Icons.assignment_outlined, t('tasks'), () => const TasksEntry()),
      _QuickAction(Icons.people_outline, t('union'), () => const UnionHomeScreen()),
      _QuickAction(Icons.menu_book_outlined, t('gradebook'), () => const GradebookScreen()),
      _QuickAction(Icons.support_agent, t('support'), () => const SupportScreen()),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.builder()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    AppIconBox(item.icon, size: 52),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Widget Function() builder;
  const _QuickAction(this.icon, this.label, this.builder);
}
