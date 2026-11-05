import '../widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../theme/app_theme.dart';
import '../models/calendar_event.dart';

class CalendarPlanScreen extends StatefulWidget {
  const CalendarPlanScreen({super.key});

  @override
  State<CalendarPlanScreen> createState() => _CalendarPlanScreenState();
}

class _CalendarPlanScreenState extends State<CalendarPlanScreen> {
  String _userGroup = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU', null);
    _loadUserGroup();
  }

  /// Та же нормализация, что в CalendarImportService.
  String _normalizeGroup(String raw) {
    return raw
        .replaceAll(RegExp(r'^ИМИ[-\s]+'), '')
        .replaceAll(RegExp(r'^ИМИ'), '')
        .trim();
  }

  Future<void> _loadUserGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      final raw = (doc.data()?['group'] as String?)?.trim() ?? '';
      setState(() {
        _userGroup = raw.isEmpty ? '' : _normalizeGroup(raw);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getColor(String component) {
    final c = component.toLowerCase();
    if (c.contains('сессия')) return Colors.red;
    if (c.contains('практика')) return Colors.green;
    if (c.contains('каникулы')) return Colors.orange;
    if (c.contains('государственн') || c.contains('гиа')) return Colors.purple;
    if (c.contains('квалификационн') || c.contains('вкр')) return Colors.purple;
    return Colors.blue;
  }

  IconData _getIcon(String component) {
    final c = component.toLowerCase();
    if (c.contains('сессия')) return Icons.assignment_late;
    if (c.contains('практика')) return Icons.work;
    if (c.contains('каникулы')) return Icons.beach_access;
    if (c.contains('государственн') || c.contains('гиа')) return Icons.verified;
    if (c.contains('квалификационн') || c.contains('вкр')) return Icons.school;
    return Icons.school;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Учебный план'),
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userGroup.isEmpty
          ? const Center(child: Text('Укажите группу в профиле'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('calendar_plan')
            .where('group', isEqualTo: _userGroup)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const AppErrorState();
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Учебный план пока не загружен.\nОбратитесь в деканат.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final events = docs
              .map((d) => CalendarEvent.fromMap(
              d.id, d.data() as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.start.compareTo(b.start));

          final fmt = DateFormat('d MMMM', 'ru_RU');
          final yearFmt = DateFormat('yyyy', 'ru_RU');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, i) {
              final e = events[i];
              final color = _getColor(e.component);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getIcon(e.component),
                          color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.component,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${e.semester} семестр',
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${fmt.format(e.start)} — ${fmt.format(e.end)} '
                                '${yearFmt.format(e.end)}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted),
                          ),
                          if (e.duration.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              e.duration,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}