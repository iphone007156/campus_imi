import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'admin_events_screen.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final UserService _userService = UserService();
  UserRole _currentRole = UserRole.student;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await _userService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        _currentRole = role;
        _isLoading = false;
      });
    }
  }

  List<AdminCardItem> get _cards {
    // Список мероприятий — доступен активистам и админам
    final cards = <AdminCardItem>[
      const AdminCardItem(
        icon: Icons.event,
        label: 'Мероприятия',
        subtitle: 'Управление',
        color: Color(0xFF7E3FBF),
      ),
    ];

    // Полные права — только у админов
    if (_currentRole == UserRole.admin) {
      cards.addAll([
        const AdminCardItem(
          icon: Icons.calendar_month,
          label: 'Управление расписанием',
          subtitle: 'Расписание',
          color: Color(0xFF3D6FA3),
        ),
        const AdminCardItem(
          icon: Icons.grade,
          label: 'Выставление оценок',
          subtitle: 'Зачётки',
          color: Color(0xFF2E7D52),
        ),
        const AdminCardItem(
          icon: Icons.people,
          label: 'Список студентов',
          subtitle: 'Роли и баллы',
          color: Color(0xFF8A5A00),
        ),
        const AdminCardItem(
          icon: Icons.campaign,
          label: 'Добавить новость',
          subtitle: 'Новости',
          color: Color(0xFFB8922A),
        ),
      ]);
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentRole == UserRole.admin
              ? 'Панель администратора'
              : 'Панель активиста',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Бейдж роли
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _currentRole == UserRole.admin
                ? Colors.red.withValues(alpha: 0.1)
                : AppTheme.gold.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  _currentRole == UserRole.admin
                      ? Icons.admin_panel_settings
                      : Icons.star,
                  color: _currentRole == UserRole.admin
                      ? Colors.red
                      : AppTheme.gold,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentRole.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _currentRole == UserRole.admin
                              ? Colors.red
                              : AppTheme.gold,
                        ),
                      ),
                      Text(
                        _currentRole == UserRole.admin
                            ? 'Полный доступ ко всем разделам'
                            : 'Максимум 20 баллов за мероприятие',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Сетка кнопок
          Expanded(
            child: GridView.builder(
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
                  subtitle: item.subtitle,
                  color: item.color,
                  onTap: () => _onCardTap(context, item.label),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onCardTap(BuildContext context, String label) {
    switch (label) {
      case 'Мероприятия':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminEventsScreen()),
        );
        break;

      case 'Список студентов':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
        );
        break;

      case 'Управление расписанием':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Раздел "Расписание" в разработке'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;

      case 'Выставление оценок':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Раздел "Оценки" в разработке'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;

      case 'Добавить новость':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Раздел "Новости" в разработке'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
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
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pop(context);
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
  final String subtitle;
  final Color color;

  const AdminCardItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.label,
    required this.subtitle,
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
          color: Colors.white,
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}