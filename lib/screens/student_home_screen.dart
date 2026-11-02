import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:async';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../services/settings_service.dart';
import 'news_screen.dart';
import 'schedule_screen.dart';
import 'gradebook_screen.dart';
import 'profile_screen.dart';
import 'union_home_screen.dart';
import 'indoor_map_screen.dart';
import 'support_screen.dart';
import 'tasks_screen.dart';
import 'settings_screen.dart';

ImageProvider? getImageProvider(Map<String, dynamic> data) {
  final photoUrl = data['photoUrl'] as String?;
  if (photoUrl != null && photoUrl.isNotEmpty) {
    return NetworkImage(photoUrl);
  }
  final base64String = data['photoBase64'] as String?;
  if (base64String == null || base64String.isEmpty) return null;
  try {
    return MemoryImage(base64Decode(base64String));
  } catch (_) {
    return null;
  }
}

class MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  const MenuItem(this.icon, this.label, this.subtitle, this.route);
}

class _MenuTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;
  const _MenuTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.s16, vertical: AppTheme.s12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(item.icon, color: Theme.of(context).colorScheme.primary, size: 22),
            ),
            const SizedBox(width: AppTheme.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(item.subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();
  @override
  Widget build(BuildContext context) {
    final langCode = SettingsService.instance.locale.languageCode;
    final t = (String key) => AppStrings.t(key, langCode);

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SupportScreen())),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.s16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.support_agent,
                    color: AppTheme.accent, size: 24),
              ),
              const SizedBox(width: AppTheme.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('support'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(t('support_sub'),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String _userName = 'Студент';
  String _userGroup = 'Группа';
  String _userInstitute = 'ИМИ СВФУ';
  ImageProvider? _userPhoto;
  bool _isLoading = true;
  StreamSubscription<DocumentSnapshot>? _userSub;

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
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['name'] ?? 'Студент';
          _userGroup = data['group'] ?? 'Группа';
          _userInstitute = data['institute'] ?? 'ИМИ СВФУ';
          _userPhoto = getImageProvider(data);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Слушаем изменения языка, чтобы меню перестраивалось
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final langCode = SettingsService.instance.locale.languageCode;
        final t = (String key) => AppStrings.t(key, langCode);

        final List<MenuItem> menuItems = [
          MenuItem(Icons.newspaper_outlined, t('news'), t('news_sub'), 'news'),
          MenuItem(Icons.assignment_outlined, t('tasks'), t('tasks_sub'), 'tasks'),
          MenuItem(Icons.calendar_today_outlined, t('schedule'), t('schedule_sub'), 'schedule'),
          MenuItem(Icons.people_outline, t('union'), t('union_sub'), 'union'),
          MenuItem(Icons.map_outlined, t('map'), t('map_sub'), 'map'),
          MenuItem(Icons.menu_book_outlined, t('gradebook'), t('gradebook_sub'), 'gradebook'),
          MenuItem(Icons.account_circle_outlined, t('profile'), t('profile_sub'), 'profile'),
        ];

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(
                      left: AppTheme.s16, bottom: AppTheme.s16),
                  background: _ProfileHeader(
                    userName: _userName,
                    userGroup: _userGroup,
                    userInstitute: _userInstitute,
                    photoProvider: _userPhoto,
                    isLoading: _isLoading,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    tooltip: 'Настройки',
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout,
                        color: Colors.white70, size: 20),
                    onPressed: () => _showLogoutDialog(context),
                    tooltip: 'Выйти',
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.s16, AppTheme.s20, AppTheme.s16, AppTheme.s8),
                sliver: SliverToBoxAdapter(
                    child: Text(t('services'),
                        style: Theme.of(context).textTheme.labelSmall)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.s16),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: AppTheme.shadowSoft,
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < menuItems.length; i++) ...[
                          _MenuTile(
                            item: menuItems[i],
                            onTap: () =>
                                _onMenuTap(context, menuItems[i].route),
                          ),
                          if (i < menuItems.length - 1)
                            const Divider(indent: 72, endIndent: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.s16),
                sliver: const SliverToBoxAdapter(child: _SupportCard()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppTheme.s24)),
            ],
          ),
        );
      },
    );
  }

  void _onMenuTap(BuildContext context, String route) {
    Widget? screen;
    switch (route) {
      case 'news':
        screen = const NewsScreen();
        break;
      case 'tasks':
        screen = const TasksEntry();
        break;
      case 'schedule':
        screen = const ScheduleScreen();
        break;
      case 'map':
        screen = const IndoorMapScreen();
        break;
      case 'gradebook':
        screen = const GradebookScreen();
        break;
      case 'profile':
        screen = const ProfileScreen();
        break;
      case 'union':
        screen = const UnionHomeScreen();
        break;
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
        content: const Text('Вы уверены, что хотите выйти из учетной записи?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
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

class _ProfileHeader extends StatelessWidget {
  final String userName;
  final String userGroup;
  final String userInstitute;
  final ImageProvider? photoProvider;
  final bool isLoading;

  const _ProfileHeader({
    required this.userName,
    required this.userGroup,
    required this.userInstitute,
    this.photoProvider,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.s20, 100, AppTheme.s20, AppTheme.s20),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 2),
              image: photoProvider != null
                  ? DecorationImage(
                  image: photoProvider!, fit: BoxFit.cover)
                  : null,
            ),
            child: isLoading
                ? const Center(
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)))
                : (photoProvider == null
                ? const Icon(Icons.person, color: Colors.white, size: 32)
                : null),
          ),
          const SizedBox(width: AppTheme.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLoading ? 'Загрузка...' : userName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading ? '...' : userGroup,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoading ? '' : userInstitute,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}