import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'admin_schedule_screen.dart';
import 'admin_events_screen.dart';
import 'admin_users_screen.dart';
import 'add_news_screen.dart';
import 'support_screen.dart';
import 'admin_groups_screen.dart';
import 'admin_export_screen.dart';
import 'admin_departments_screen.dart';
import 'admin_calendar_import_screen.dart';
import 'admin_import_calendar_screen.dart'; // ✅ Импорт нового экрана
import 'admin_reports_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const List<_AdminCardItem> _cards = [
    _AdminCardItem(icon: Icons.calendar_month, label: 'Расписание', subtitle: 'Управление занятиями', color: Color(0xFF3D6FA3)),
    _AdminCardItem(icon: Icons.group_add, label: 'Группы', subtitle: 'Список всех групп', color: Color(0xFF7E3FBF)),
    _AdminCardItem(icon: Icons.event_available, label: 'Мероприятия', subtitle: 'Создание и отметки', color: Color(0xFF2E7D52)),
    _AdminCardItem(icon: Icons.people, label: 'Студенты', subtitle: 'Роли и баллы', color: Color(0xFF8A5A00)),
    _AdminCardItem(icon: Icons.campaign, label: 'Новости', subtitle: 'Публикация', color: Color(0xFFB8922A)),
    _AdminCardItem(icon: Icons.file_download_outlined, label: 'Экспорт в Excel', subtitle: 'Выгрузка данных студентов', color: Colors.teal),
    _AdminCardItem(icon: Icons.apartment, label: 'Подразделения', subtitle: 'Институты и колледжи', color: Colors.indigo),
    _AdminCardItem(icon: Icons.calendar_today, label: 'Учебный план', subtitle: 'Импорт КУГ из Excel', color: Colors.deepPurple),
    _AdminCardItem(icon: Icons.date_range, label: 'График недель', subtitle: 'Четность семестра', color: Colors.blueAccent), // ✅ Новый пункт
    _AdminCardItem(icon: Icons.support_agent, label: 'Техподдержка', subtitle: 'Обращения студентов', color: Color(0xFFFF6B35)),
    _AdminCardItem(icon: Icons.flag_outlined, label: 'Жалобы', subtitle: 'Сообщения из чатов групп', color: Color(0xFFB3261E)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель администратора'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _showLogoutDialog(context)),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ Динамический фон
      body: ListView.separated(
        padding: const EdgeInsets.all(AppTheme.s16),
        itemCount: _cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.s12),
        itemBuilder: (context, i) {
          final item = _cards[i];
          return _AdminTile(item: item, onTap: () => _handleTap(context, item.label));
        },
      ),
    );
  }

  void _handleTap(BuildContext context, String label) {
    Widget? screen;
    switch (label) {
      case 'Расписание': screen = const AdminScheduleScreen(); break;
      case 'Группы': screen = const AdminGroupsScreen(); break;
      case 'Мероприятия': screen = const AdminEventsScreen(); break;
      case 'Студенты': screen = const AdminUsersScreen(); break;
      case 'Новости': screen = const AddNewsScreen(); break;
      case 'Подразделения': screen = const AdminDepartmentsScreen(); break;
      case 'Техподдержка': screen = const SupportScreen(); break;
      case 'Жалобы': screen = const AdminReportsScreen(); break;
      case 'Экспорт в Excel': screen = const AdminExportScreen(); break;
      case 'Учебный план': screen = const AdminCalendarImportScreen(); break;
      case 'График недель': screen = const AdminImportCalendarScreen(); break; // ✅ Навигация
    }
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AdminCardItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _AdminCardItem({required this.icon, required this.label, required this.subtitle, required this.color});
}

class _AdminTile extends StatelessWidget {
  final _AdminCardItem item;
  final VoidCallback onTap;
  const _AdminTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor, // ✅ Динамический цвет карточки
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.s16),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(item.icon, color: item.color, size: 26),
              ),
              const SizedBox(width: AppTheme.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(item.subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.disabledColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
