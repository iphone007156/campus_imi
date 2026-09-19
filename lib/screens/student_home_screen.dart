import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import 'news_screen.dart';
import 'schedule_screen.dart';
import 'gradebook_screen.dart';
import 'profile_screen.dart';
import 'union_home_screen.dart';

// --- Функция для декодирования Base64 ---
ImageProvider? getImageFromBase64(String? base64String) {
  if (base64String == null || base64String.isEmpty) return null;
  try {
    final bytes = base64Decode(base64String);
    return MemoryImage(bytes);
  } catch (e) {
    return null;
  }
}

// --- Вспомогательные классы ---

class MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;

  const MenuItem(this.icon, this.label, this.subtitle);
}

class MenuTile extends StatelessWidget {
  final MenuItem item;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const MenuTile({
    super.key,
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 12 : 0),
      topRight: Radius.circular(isFirst ? 12 : 0),
      bottomLeft: Radius.circular(isLast ? 12 : 0),
      bottomRight: Radius.circular(isLast ? 12 : 0),
    );

    return Material(
      color: AppTheme.cardWhite,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
              bottom: BorderSide(color: AppTheme.divider, width: 0.5),
            ),
          ),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(item.icon, color: AppTheme.accentBlue, size: 20),
            ),
            title: Text(
              item.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            subtitle: Text(
              item.subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppTheme.textMuted, size: 20),
          ),
        ),
      ),
    );
  }
}

class SupportCard extends StatelessWidget {
  const SupportCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.support_agent,
                color: AppTheme.accentBlue, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Техническая поддержка',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Нужна помощь? Напишите нам',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
        ],
      ),
    );
  }
}

// --- ОСНОВНОЙ ЭКРАН ---

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String _userName = 'Студент';
  String _userGroup = 'Группа';
  String _userInstitute = 'ИМИ СВФУ';
  String? _userPhotoBase64;
  bool _isLoading = true;

  final List<MenuItem> _menuItems = const [
    MenuItem(Icons.newspaper_outlined, 'Новости', 'Последние события'),
    MenuItem(Icons.assignment_outlined, 'Задания', 'Учебные задания'),
    MenuItem(Icons.calendar_today_outlined, 'Расписание', 'Расписание занятий'),
    MenuItem(Icons.people_outline, 'Профсоюз', 'Студенческий профсоюз'),
    MenuItem(Icons.map_outlined, 'Карта', 'Карта кампуса'),
    MenuItem(Icons.menu_book_outlined, 'Зачётка', 'Оценки и зачёты'),
    MenuItem(Icons.account_circle_outlined, 'Профиль', 'Личный кабинет'),
  ];

  @override
  void initState() {
    super.initState();
    _listenToUserData();
  }

  void _listenToUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['name'] ?? 'Студент';
          _userGroup = data['group'] ?? 'Группа';
          _userInstitute = data['institute'] ?? 'ИМИ СВФУ';
          _userPhotoBase64 = data['photoBase64'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }, onError: (error) {
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = getImageFromBase64(_userPhotoBase64);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // ✅ Высота шапки — оптимальная
            expandedHeight: 230,
            pinned: true,
            backgroundColor: AppTheme.primaryNavy,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              // ✅ Заголовок опущен ниже
              centerTitle: true,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              background: ProfileHeader(
                userName: _userName,
                userGroup: _userGroup,
                userInstitute: _userInstitute,
                photoProvider: photoProvider,
                isLoading: _isLoading,
              ),
            ),
            title: const Text('Главное меню'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                onPressed: () => _showLogoutDialog(context),
                tooltip: 'Выйти',
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'СЕРВИСЫ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item = _menuItems[index];
                  return MenuTile(
                    item: item,
                    isFirst: index == 0,
                    isLast: index == _menuItems.length - 1,
                    onTap: () => _onMenuTap(context, item.label),
                  );
                },
                childCount: _menuItems.length,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(child: const SupportCard()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _onMenuTap(BuildContext context, String label) {
    Widget? screen;
    switch (label) {
      case 'Новости':
        screen = const NewsScreen();
        break;
      case 'Расписание':
        screen = const ScheduleScreen();
        break;
      case 'Зачётка':
        screen = const GradebookScreen();
        break;
      case 'Профиль':
        screen = const ProfileScreen();
        break;
      case 'Профсоюз':
        screen = const UnionHomeScreen();
        break;
    }
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Раздел "$label" в разработке'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppTheme.primaryNavy,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из учетной записи?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ошибка при выходе')),
                );
              }
            },
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- ШАПКА ПРОФИЛЯ ---

class ProfileHeader extends StatelessWidget {
  final String userName;
  final String userGroup;
  final String userInstitute;
  final ImageProvider? photoProvider;
  final bool isLoading;

  const ProfileHeader({
    super.key,
    required this.userName,
    required this.userGroup,
    required this.userInstitute,
    this.photoProvider,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ ОТРЕГУЛИРОВАЛИ ОТСТУПЫ:
      // top: 100 — опустили аватарку ниже от заголовка "Главное меню"
      // bottom: 20 — убрали пустое место снизу
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryNavy, Color(0xFF2C4A8A)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Аватар — слева
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2.5,
              ),
              image: photoProvider != null
                  ? DecorationImage(
                image: photoProvider!,
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : (photoProvider == null
                ? const Icon(Icons.person, color: Colors.white, size: 38)
                : null),
          ),
          const SizedBox(width: 16),

          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLoading ? 'Загрузка...' : userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isLoading ? '...' : userGroup,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading ? '' : userInstitute,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
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