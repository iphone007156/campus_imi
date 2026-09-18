import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToUserData();  // ← Слушаем изменения
  }

  // 🔄 Слушаем изменения в Firestore
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
        setState(() {
          _userData = snapshot.data() as Map<String, dynamic>;
          _isLoading = false;
        });
        print('🔄 Данные профиля обновлены автоматически!');
      } else {
        setState(() => _isLoading = false);
      }
    }, onError: (error) {
      print('❌ Ошибка загрузки данных: $error');
      setState(() => _isLoading = false);
    });
  }

  // Декодирование Base64 в ImageProvider
  ImageProvider? _getImageFromBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      print('❌ Ошибка декодирования фото: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем фото из Base64
    final photoProvider = _getImageFromBase64(_userData['photoBase64']);

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
      backgroundColor: AppTheme.backgroundGray,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Аватар блок
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.lightBlue,
                    border: Border.all(
                      color: AppTheme.accentBlue,
                      width: 2.5,
                    ),
                    image: photoProvider != null
                        ? DecorationImage(
                      image: photoProvider,
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: photoProvider == null
                      ? const Icon(Icons.person,
                      size: 48, color: AppTheme.accentBlue)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _userData['name'] ?? 'Студент',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _userData['group'] ?? 'Группа',
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Информационные блоки
          _InfoSection(
            title: 'УЧЁБА',
            items: [
              _InfoRow(
                Icons.school_outlined,
                'Институт',
                _userData['institute'] ?? 'ИМИ СВФУ',
              ),
              _InfoRow(
                Icons.groups_outlined,
                'Группа',
                _userData['group'] ?? 'Группа',
              ),
              _InfoRow(
                Icons.layers_outlined,
                'Курс',
                _userData['course'] ?? '1 курс',
              ),
              _InfoRow(
                Icons.category_outlined,
                'Направление',
                _userData['direction'] ?? 'Прикладная математика',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: 'КОНТАКТЫ',
            items: [
              _InfoRow(
                Icons.email_outlined,
                'Email',
                _userData['email'] ?? 'email@example.com',
              ),
              _InfoRow(
                Icons.phone_outlined,
                'Телефон',
                _userData['phone'] ?? '+7 (999) 000-00-00',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Кнопка выхода
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                'Выйти из аккаунта',
                style: TextStyle(color: Colors.redAccent),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(userData: _userData),
      ),
    );

    // После редактирования данные обновятся автоматически через Stream
    if (result == true) {
      print('✅ Профиль обновлён, данные перезагрузятся автоматически');
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
              if (mounted) {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ---

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> items;

  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Container(
                color: AppTheme.cardWhite,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        item.icon,
                        color: AppTheme.accentBlue,
                        size: 20,
                      ),
                      title: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      subtitle: Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    if (i < items.length - 1)
                      const Divider(
                        height: 1,
                        indent: 52,
                        color: AppTheme.divider,
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);
}