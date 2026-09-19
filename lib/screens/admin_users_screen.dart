import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';
  String _filterRole = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список студентов'),
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          // Поиск
          Container(
            color: AppTheme.cardWhite,
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по имени или группе...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Фильтры по роли
          Container(
            color: AppTheme.cardWhite,
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RoleFilterChip(
                  label: 'Все',
                  selected: _filterRole == 'all',
                  onTap: () => setState(() => _filterRole = 'all'),
                ),
                _RoleFilterChip(
                  label: '👤 Студенты',
                  selected: _filterRole == 'student',
                  onTap: () => setState(() => _filterRole = 'student'),
                ),
                _RoleFilterChip(
                  label: '⭐ Активисты',
                  selected: _filterRole == 'activist',
                  onTap: () => setState(() => _filterRole = 'activist'),
                ),
                _RoleFilterChip(
                  label: '🔑 Админы',
                  selected: _filterRole == 'admin',
                  onTap: () => setState(() => _filterRole = 'admin'),
                ),
              ],
            ),
          ),

          // Список пользователей
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Ошибка: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Нет пользователей'),
                  );
                }

                var users = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'uid': doc.id,
                    'name': data['name'] ?? 'Без имени',
                    'group': data['group'] ?? '—',
                    'email': data['email'] ?? '—',
                    'role': data['role']?.toString() ?? 'student',
                    'unionPoints': data['unionPoints'] ?? 0,
                  };
                }).toList();

                // Фильтр по роли
                if (_filterRole != 'all') {
                  users = users
                      .where((u) => u['role'] == _filterRole)
                      .toList();
                }

                // Фильтр по поиску
                if (_searchQuery.isNotEmpty) {
                  users = users.where((u) {
                    final name = (u['name'] as String).toLowerCase();
                    final group = (u['group'] as String).toLowerCase();
                    return name.contains(_searchQuery) ||
                        group.contains(_searchQuery);
                  }).toList();
                }

                if (users.isEmpty) {
                  return const Center(
                    child: Text('Пользователи не найдены'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final user = users[i];
                    return _UserRoleCard(
                      uid: user['uid'] as String,
                      name: user['name'] as String,
                      group: user['group'] as String,
                      email: user['email'] as String,
                      role: user['role'] as String,
                      points: int.tryParse(user['unionPoints'].toString()) ?? 0,
                      onRoleChanged: (newRole) async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user['uid'])
                            .update({'role': newRole});
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===== ФИЛЬТР ПО РОЛИ =====
class _RoleFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryNavy : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textDark,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ===== КАРТОЧКА ПОЛЬЗОВАТЕЛЯ =====
class _UserRoleCard extends StatelessWidget {
  final String uid;
  final String name;
  final String group;
  final String email;
  final String role;
  final int points;
  final Function(String) onRoleChanged;

  const _UserRoleCard({
    required this.uid,
    required this.name,
    required this.group,
    required this.email,
    required this.role,
    required this.points,
    required this.onRoleChanged,
  });

  Color get _roleColor {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'activist':
        return Colors.green;
      default:
        return AppTheme.accentBlue;
    }
  }

  String get _roleLabel {
    switch (role) {
      case 'admin':
        return 'Админ';
      case 'activist':
        return 'Активист';
      default:
        return 'Студент';
    }
  }

  IconData get _roleIcon {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'activist':
        return Icons.star;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: role == 'student'
                  ? AppTheme.divider
                  : _roleColor.withValues(alpha: 0.3),
              width: role == 'student' ? 1 : 1.5,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Аватар с ролью
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _roleColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _roleColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(_roleIcon, color: _roleColor, size: 24),
              ),
              const SizedBox(width: 12),

              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.groups_outlined,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          group,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.star,
                            size: 12, color: AppTheme.gold),
                        const SizedBox(width: 4),
                        Text(
                          '$points',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.gold,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Меню выбора роли
              PopupMenuButton<String>(
                onSelected: onRoleChanged,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'student',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: AppTheme.accentBlue, size: 20),
                        SizedBox(width: 8),
                        Text('Студент'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'activist',
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Активист'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings,
                            color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Админ'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _roleLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: _roleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down,
                          color: _roleColor, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}