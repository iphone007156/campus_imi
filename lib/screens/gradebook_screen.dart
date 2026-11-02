import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../theme/app_theme.dart';
import '../models/subject.dart';
import '../models/calendar_event.dart';
import '../services/firestore_service.dart';
import '../l10n/app_strings.dart';
import '../services/settings_service.dart';

class GradebookScreen extends StatefulWidget {
  const GradebookScreen({super.key});

  @override
  State<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends State<GradebookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _userName = 'Студент';
  String _userGroup = 'Группа';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU', null);
    _tab = TabController(length: 2, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? 'Студент';
          _userGroup = doc.data()?['group'] ?? 'Группа';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = SettingsService.instance.locale.languageCode;
    final t = (String key) => AppStrings.t(key, langCode);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('gradebook')),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: t('grades')),
            Tab(text: t('plan')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _GradesTab(userName: _userName, userGroup: _userGroup),
          _PlanTab(userName: _userName, userGroup: _userGroup),
        ],
      ),
    );
  }
}

// ==================== ВКЛАДКА 1: ОЦЕНКИ ====================

class _GradesTab extends StatelessWidget {
  final String userName;
  final String userGroup;
  const _GradesTab({required this.userName, required this.userGroup});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final langCode = SettingsService.instance.locale.languageCode;
    final t = (String key) => AppStrings.t(key, langCode);

    return StreamBuilder<List<Subject>>(
      stream: firestoreService.getSubjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final subjects = snapshot.data ?? [];
        final graded = subjects.where((s) => s.grade != null).toList();
        final double gpa = graded.isEmpty
            ? 0
            : graded.map((s) => s.grade!).reduce((a, b) => a + b) / graded.length;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(name: userName, group: userGroup),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GpaCard(
                    gpa: gpa,
                    totalSubjects: subjects.length,
                    gradedCount: graded.length,
                    langCode: langCode,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        t('subjects'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Семестр 1',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (subjects.isEmpty)
                    _EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: t('no_grades'),
                      subtitle: 'Оценки появятся после первой сессии',
                    )
                  else
                    ...subjects.map((s) => _SubjectTile(subject: s)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String group;
  const _ProfileHeader({required this.name, required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    group,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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

class _GpaCard extends StatelessWidget {
  final double gpa;
  final int totalSubjects;
  final int gradedCount;
  final String langCode;

  const _GpaCard({
    required this.gpa,
    required this.totalSubjects,
    required this.gradedCount,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    final debts = totalSubjects - gradedCount;
    final t = (String key) => AppStrings.t(key, langCode);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.shadowSoft,
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('avg_score'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        gpa.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ 5.0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: gpa >= 4.5 ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  gpa >= 4.5 ? Icons.star_rounded : Icons.trending_up_rounded,
                  color: gpa >= 4.5 ? Colors.green : Colors.orange,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatItem(label: 'Всего', value: '$totalSubjects', color: AppTheme.accentBlue),
              _StatItem(label: 'Сдано', value: '$gradedCount', color: Colors.green),
              _StatItem(label: 'Долги', value: '$debts', color: debts > 0 ? Colors.red : Colors.green),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final Subject subject;
  const _SubjectTile({required this.subject});

  @override
  Widget build(BuildContext context) {
    final isGraded = subject.grade != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isGraded ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isGraded ? Icons.check_circle_outline : Icons.hourglass_empty,
              color: isGraded ? Theme.of(context).colorScheme.primary : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '${subject.type} • ${subject.teacher}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          if (isGraded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getGradeColor(subject.grade!).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${subject.grade}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _getGradeColor(subject.grade!),
                ),
              ),
            )
          else if (subject.gradeText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                subject.gradeText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            )
          else
            Text(
              '—',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
        ],
      ),
    );
  }

  Color _getGradeColor(int grade) {
    if (grade == 5) return Colors.green;
    if (grade == 4) return AppTheme.accentBlue;
    if (grade == 3) return Colors.orange;
    return Colors.red;
  }
}

// ==================== ВКЛАДКА 2: УЧЕБНЫЙ ПЛАН ====================

class _PlanTab extends StatefulWidget {
  final String userName;
  final String userGroup;
  const _PlanTab({required this.userName, required this.userGroup});

  @override
  State<_PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<_PlanTab> {
  String _userGroup = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userGroup = _normalizeGroup(widget.userGroup);
    _isLoading = false;
  }

  String _normalizeGroup(String raw) {
    return raw
        .replaceAll(RegExp(r'^ИМИ[-\s]+'), '')
        .replaceAll(RegExp(r'^ИМИ'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_userGroup.isEmpty) {
      return const Center(child: Text('Укажите группу в профиле'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('calendar_plan')
          .where('group', isEqualTo: _userGroup)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.event_busy,
            title: 'Учебный план не загружен',
            subtitle: 'Для вашей группы данные пока отсутствуют.\nОбратитесь в деканат.',
          );
        }

        final events = docs
            .map((d) => CalendarEvent.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

        final now = DateTime.now();
        final upcoming = events.where((e) => e.end.isAfter(now)).toList();
        final past = events.where((e) => e.end.isBefore(now)).toList();

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(name: widget.userName, group: _userGroup),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (upcoming.isNotEmpty) ...[
                    const _SectionTitle('ПРЕДСТОЯЩИЕ СОБЫТИЯ', color: Colors.green),
                    const SizedBox(height: 12),
                    ...upcoming.map((e) => _PlanCard(event: e, isUpcoming: true)),
                  ],
                  if (upcoming.isNotEmpty && past.isNotEmpty)
                    const SizedBox(height: 24),
                  if (past.isNotEmpty) ...[
                    const _SectionTitle('ПРОШЕДШИЕ СОБЫТИЯ', color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    ...past.map((e) => _PlanCard(event: e, isUpcoming: false)),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle(this.title, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final CalendarEvent event;
  final bool isUpcoming;
  const _PlanCard({required this.event, required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    final color = _getColor(event.component);
    final fmt = DateFormat('d MMM', 'ru_RU');
    final yearFmt = DateFormat('yyyy', 'ru_RU');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUpcoming ? Theme.of(context).cardColor : Theme.of(context).cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUpcoming ? color.withValues(alpha: 0.3) : Theme.of(context).dividerColor,
        ),
        boxShadow: isUpcoming ? AppTheme.shadowSoft : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 80,
              color: isUpcoming ? color : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${event.semester} семестр',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (event.duration.isNotEmpty)
                          Text(
                            event.duration,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.component,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        color: isUpcoming ? Theme.of(context).textTheme.titleMedium?.color : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(
                          '${fmt.format(event.start)} — ${fmt.format(event.end)} ${yearFmt.format(event.end)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                        ),
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

  Color _getColor(String component) {
    final c = component.toLowerCase();
    if (c.contains('сессия')) return Colors.red;
    if (c.contains('практика')) return Colors.green;
    if (c.contains('каникулы')) return Colors.orange;
    if (c.contains('государственн') || c.contains('гиа')) return Colors.purple;
    return AppTheme.accentBlue;
  }
}

// ==================== ОБЩИЕ ВИДЖЕТЫ ====================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadowSoft,
              ),
              child: Icon(icon, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}