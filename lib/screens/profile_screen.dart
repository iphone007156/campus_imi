import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'dart:convert';
import 'dart:async';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import 'edit_profile_screen.dart';
import 'admin_home_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  /// true — экран внутри нижней навигации (без стрелки «назад»).
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

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

  /// Удаление аккаунта: подтверждаем паролем (Firebase требует свежий вход),
  /// затем удаляем данные профиля и сам аккаунт.
  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Профиль и ваши данные будут удалены без возможности '
                  'восстановления. Чтобы подтвердить, введите пароль.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Пароль'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text(
              'Удалить',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (password == null || password.isEmpty) return;
    if (!context.mounted) return;
    await _deleteAccount(context, password);
  }

  Future<void> _deleteAccount(BuildContext context, String password) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось определить аккаунт. Войдите заново.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    var progressOpen = true;
    void closeProgress() {
      if (progressOpen) {
        progressOpen = false;
        navigator.pop();
      }
    }

    try {
      // 1. Подтверждение личности. Без него удаление аккаунта может не пройти
      // уже после того, как профиль стёрт, и пользователь останется «без профиля».
      final credential =
      EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);

      // 2. Данные профиля.
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // 3. Push-подписка.
      try {
        OneSignal.logout();
      } catch (_) {}

      // 4. Сам аккаунт (одна повторная попытка при сбое сети).
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'network-request-failed') {
          await user.delete();
        } else {
          rethrow;
        }
      }

      closeProgress();
      navigator.popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      closeProgress();
      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Неверный пароль';
          break;
        case 'too-many-requests':
          message = 'Слишком много попыток. Попробуйте позже.';
          break;
        case 'network-request-failed':
          message = 'Нет подключения к интернету';
          break;
        default:
          message = 'Не удалось удалить аккаунт (${e.code}). Войдите заново и повторите.';
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on FirebaseException {
      closeProgress();
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось удалить данные профиля. Попробуйте позже.')),
      );
    } catch (_) {
      closeProgress();
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось удалить аккаунт. Попробуйте позже.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = _getImageProvider(_userData);
    final isAdmin = _userData['role'] == 'admin';
    final theme = Theme.of(context);
    final headerBg = theme.appBarTheme.backgroundColor ?? AppTheme.primaryNavy;
    final headerFg = theme.appBarTheme.foregroundColor ?? Colors.white;
    final name = (_userData['name'] ?? 'Студент').toString();
    final group = (_userData['group'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Редактировать профиль',
            onPressed: _isLoading ? null : _navigateToEditProfile,
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: EdgeInsets.zero,
        children: [
          // ─── ШАПКА ПРОФИЛЯ ───────────────────────────────
          Container(
            color: headerBg,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white, width: 3),
                    image: photoProvider != null
                        ? DecorationImage(image: photoProvider, fit: BoxFit.cover)
                        : null,
                  ),
                  child: photoProvider == null
                      ? Icon(Icons.person, size: 44, color: headerFg)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: headerFg,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (group.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Text(
                      group,
                      style: TextStyle(
                        color: headerFg,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── УЧЕБА ──────────────────────────────────
                const AppSectionLabel('Учёба'),
                _InfoCard(items: [
                  _InfoRow(Icons.school_outlined, 'Подразделение',
                      (_userData['institute'] ?? 'ИМИ СВФУ').toString()),
                  _InfoRow(Icons.groups_outlined, 'Группа',
                      (_userData['group'] ?? '—').toString()),
                  _InfoRow(Icons.layers_outlined, 'Курс',
                      (_userData['course'] ?? '—').toString()),
                ]),

                // ─── КОНТАКТЫ ───────────────────────────────
                const AppSectionLabel('Контакты'),
                _InfoCard(items: [
                  _InfoRow(Icons.email_outlined, 'Email',
                      (_userData['email'] ?? '—').toString()),
                  _InfoRow(Icons.phone_outlined, 'Телефон',
                      (_userData['phone'] ?? '—').toString()),
                ]),

                // ─── НАСТРОЙКИ ──────────────────────────────
                const AppSectionLabel('Настройки'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      AppListRow(
                        icon: Icons.notifications_outlined,
                        title: 'Уведомления',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationSettingsScreen()),
                        ),
                      ),
                      const Divider(height: 1, indent: 64),
                      AppListRow(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Конфиденциальность',
                        subtitle: 'Согласие на обработку данных получено',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen()),
                        ),
                      ),
                      if (isAdmin) ...[
                        const Divider(height: 1, indent: 64),
                        AppListRow(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Панель управления',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminHomeScreen()),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ─── АККАУНТ ────────────────────────────────
                const AppSectionLabel('Аккаунт'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      AppListRow(
                        icon: Icons.logout,
                        title: 'Выйти из аккаунта',
                        tone: AppTone.neutral,
                        onTap: () => _showLogoutDialog(context),
                      ),
                      const Divider(height: 1, indent: 64),
                      AppListRow(
                        icon: Icons.delete_outline,
                        title: 'Удалить аккаунт',
                        subtitle: 'Профиль и данные будут удалены безвозвратно',
                        tone: AppTone.danger,
                        onTap: () => _showDeleteAccountDialog(context),
                      ),
                    ],
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

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1) const Divider(height: 1, indent: 64),
          ],
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.s12, vertical: 10),
      child: Row(
        children: [
          AppIconBox(icon, size: 40),
          const SizedBox(width: AppTheme.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: appMutedColor(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
