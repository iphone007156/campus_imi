import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'admin_schedule_screen.dart';
import 'admin_events_screen.dart';
import 'admin_users_screen.dart';
import 'add_news_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const List<AdminCardItem> _cards = [
    AdminCardItem(
      icon: Icons.calendar_month,
      label: 'Управление расписанием',
      color: Color(0xFF3D6FA3),
    ),
    AdminCardItem(
      icon: Icons.event_available,
      label: 'Управление мероприятиями',
      color: Color(0xFF2E7D52),
    ),
    AdminCardItem(
      icon: Icons.people,
      label: 'Список студентов',
      color: Color(0xFF8A5A00),
    ),
    AdminCardItem(
      icon: Icons.campaign,
      label: 'Добавить новость',
      color: Color(0xFFB8922A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель администратора'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.1,
        ),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final item = _cards[index];
          return _AdminCard(
            icon: item.icon,
            label: item.label,
            color: item.color,
            onTap: () => _handleTap(context, item.label),
          );
        },
      ),
    );
  }

  void _handleTap(BuildContext context, String label) {
    Widget? screen;
    switch (label) {
      case 'Управление расписанием':
        screen = const AdminScheduleScreen();
        break;
      case 'Управление мероприятиями':
        screen = const AdminEventsScreen();
        break;
      case 'Список студентов':
        screen = const AdminUsersScreen();
        break;
      case 'Добавить новость':
        screen = const AddNewsScreen();
        break;
    }

    if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen!),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Раздел "$label" в разработке'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AdminCardItem {
  final IconData icon;
  final String label;
  final Color color;

  const AdminCardItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}