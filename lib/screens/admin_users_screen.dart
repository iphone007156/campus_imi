import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';
  String _filterRole = 'all';
  String _sortBy = 'name'; // 'name' | 'points'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список студентов'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Сортировка',
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'name'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 20,
                      color: AppTheme.accentBlue,
                    ),
                    const SizedBox(width: 8),
                    const Text('По имени'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'points',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'points'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 20,
                      color: AppTheme.gold,
                    ),
                    const SizedBox(width: 8),
                    const Text('По баллам'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
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
                    'unionPoints':
                    int.tryParse(data['unionPoints']?.toString() ?? '0') ??
                        0,
                  };
                }).toList();

                if (_filterRole != 'all') {
                  users =
                      users.where((u) => u['role'] == _filterRole).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  users = users.where((u) {
                    final name = (u['name'] as String).toLowerCase();
                    final group = (u['group'] as String).toLowerCase();
                    return name.contains(_searchQuery) ||
                        group.contains(_searchQuery);
                  }).toList();
                }

                if (_sortBy == 'points') {
                  users.sort((a, b) => (b['unionPoints'] as int)
                      .compareTo(a['unionPoints'] as int));
                } else {
                  users.sort((a, b) =>
                      (a['name'] as String).compareTo(b['name'] as String));
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
                      points: user['unionPoints'] as int,
                      rank: _sortBy == 'points' ? i + 1 : null,
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
  final int? rank;
  final Function(String) onRoleChanged;

  const _UserRoleCard({
    required this.uid,
    required this.name,
    required this.group,
    required this.email,
    required this.role,
    required this.points,
    required this.onRoleChanged,
    this.rank,
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

  Color get _pointsColor {
    if (points >= 100) return Colors.green;
    if (points >= 50) return AppTheme.accentBlue;
    if (points >= 20) return Colors.orange;
    return AppTheme.textMuted;
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
              Stack(
                children: [
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
                  if (rank != null && rank! <= 3)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: rank == 1
                              ? AppTheme.gold
                              : (rank == 2 ? Colors.grey : Colors.brown),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _pointsColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _pointsColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star,
                                  color: _pointsColor, size: 14),
                              const SizedBox(width: 3),
                              Text(
                                '$points',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _pointsColor,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'баллов',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _pointsColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.groups_outlined,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            group,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
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
              PopupMenuButton<String>(
                onSelected: onRoleChanged,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'student',
                    child: Row(
                      children: [
                        Icon(Icons.person,
                            color: AppTheme.accentBlue, size: 20),
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
                    border:
                    Border.all(color: _roleColor.withValues(alpha: 0.3)),
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