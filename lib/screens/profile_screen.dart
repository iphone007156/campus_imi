import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'dart:convert';
import 'dart:async';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'admin_home_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userData = {};
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
        setState(() {
          _userData = snapshot.data() as Map<String, dynamic>;
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

  ImageProvider? _getImageProvider(Map<String, dynamic> data) {
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

  void _navigateToEditProfile() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => EditProfileScreen(userData: _userData)));
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
              child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text(
            'Все ваши данные будут удалены в течение 30 дней. '
                'Это действие необратимо.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .delete();

                try {
                  OneSignal.logout();
                } catch (_) {}

                await user.delete();

                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ошибка удаления: ${e.message ?? e.code}. '
                            'Попробуйте войти заново и повторить.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = _getImageProvider(_userData);
    final isAdmin = _userData['role'] == 'admin';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _isLoading ? null : _navigateToEditProfile,
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(AppTheme.s16),
        children: [
          // ─── ШАПКА ПРОФИЛЯ ───────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    border: Border.all(
                        color: Theme.of(context).cardColor, width: 4),
                    image: photoProvider != null
                        ? DecorationImage(
                        image: photoProvider, fit: BoxFit.cover)
                        : null,
                    boxShadow: AppTheme.shadowSoft,
                  ),
                  child: photoProvider == null
                      ? Icon(Icons.person,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
                const SizedBox(height: AppTheme.s16),
                Text(
                  _userData['name'] ?? 'Студент',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius:
                    BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Text(
                    _userData['group'] ?? 'Группа',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: AppTheme.s24),
              ],
            ),
          ),

          // ─── БЛОК НАСТРОЕК И ПРАВОВОЙ ИНФОРМАЦИИ ────────
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.shadowSoft,
            ),
            child: Column(
              children: [
                // Уведомления
                ListTile(
                  leading: Icon(Icons.notifications_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  title: const Text('Уведомления'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const NotificationSettingsScreen()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),

                // Политика конфиденциальности
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  title: const Text('Политика конфиденциальности'),
                  subtitle: const Text(
                    'Согласие на обработку данных получено',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen()),
                    );
                  },
                ),

                // Панель управления (только для админа)
                if (isAdmin) ...[
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.admin_panel_settings_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    title: const Text('Панель управления'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminHomeScreen()),
                      );
                    },
                  ),
                ],

                const Divider(height: 1, indent: 56, endIndent: 16),

                // Выйти
                ListTile(
                  leading:
                  const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Выйти из аккаунта',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ─── УЧЕБА ────────────────────────────────────────
          _InfoSection(
            title: 'УЧЕБА',
            items: [
              _InfoRow(Icons.school_outlined, 'Подразделение',
                  _userData['institute'] ?? 'ИМИ СВФУ'),
              _InfoRow(Icons.groups_outlined, 'Группа',
                  _userData['group'] ?? '---'),
              _InfoRow(Icons.layers_outlined, 'Курс',
                  _userData['course'] ?? '---'),
            ],
          ),
          const SizedBox(height: AppTheme.s16),

          // ─── КОНТАКТЫ ─────────────────────────────────────
          _InfoSection(
            title: 'КОНТАКТЫ',
            items: [
              _InfoRow(Icons.email_outlined, 'Email',
                  _userData['email'] ?? '---'),
              _InfoRow(Icons.phone_outlined, 'Телефон',
                  _userData['phone'] ?? '---'),
            ],
          ),
          const SizedBox(height: 32),

          // ─── УДАЛЕНИЕ АККАУНТА (в самом низу) ─────────────
          Center(
            child: TextButton(
              onPressed: () => _showDeleteAccountDialog(context),
              style: TextButton.styleFrom(
                foregroundColor:
                Theme.of(context).textTheme.bodySmall?.color,
              ),
              child: const Text(
                'Удалить аккаунт',
                style: TextStyle(
                    fontSize: 13, decoration: TextDecoration.underline),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.s24),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> items;
  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: AppTheme.s8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.shadowSoft,
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(height: 1, indent: 56, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.s16, vertical: AppTheme.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon,
                color: Theme.of(context).colorScheme.primary, size: 18),
          ),
          const SizedBox(width: AppTheme.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}