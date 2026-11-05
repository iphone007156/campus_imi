import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/group_models.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';
  String _sortBy = 'name';
  String _selectedRoleFilter = 'Все';
  final List<String> _roleFilters = ['Все', 'Студент', 'Староста', 'Заместитель', 'Активист', 'Админ'];

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
              const PopupMenuItem(value: 'name', child: Text('По имени')),
              const PopupMenuItem(value: 'points', child: Text('По баллам')),
            ],
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по имени, группе или подразделению...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Text('Роль:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRoleFilter,
                      isExpanded: true,
                      dropdownColor: Theme.of(context).cardColor,
                      items: _roleFilters.map((role) {
                        return DropdownMenuItem(value: role, child: Text(role, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedRoleFilter = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var users = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  List<GroupRole> roles = [];
                  if (data['roles'] is List) {
                    roles = rolesFromStringList(data['roles']);
                  } else if (data['groupRole'] != null) {
                    roles = [roleFromString(data['groupRole'] as String?)];
                  } else {
                    roles = [GroupRole.student];
                  }
                  if (data['role'] == 'admin' && !roles.contains(GroupRole.admin)) {
                    roles.add(GroupRole.admin);
                  }

                  return {
                    'uid': doc.id,
                    'name': data['name'] ?? 'Без имени',
                    'group': data['group'] ?? '---',
                    'departmentId': data['departmentId'] ?? '',
                    'institute': data['institute'] ?? '---',
                    'email': data['email'] ?? '---',
                    'roles': roles,
                    'unionPoints': int.tryParse(data['unionPoints']?.toString() ?? '0') ?? 0,
                  };
                }).toList();

                if (_searchQuery.isNotEmpty) {
                  users = users.where((u) =>
                  (u['name'] as String).toLowerCase().contains(_searchQuery) ||
                      (u['group'] as String).toLowerCase().contains(_searchQuery) ||
                      (u['institute'] as String).toLowerCase().contains(_searchQuery)).toList();
                }

                if (_selectedRoleFilter != 'Все') {
                  users = users.where((u) {
                    final List<GroupRole> roles = u['roles'];
                    if (_selectedRoleFilter == 'Админ') return roles.contains(GroupRole.admin);
                    if (_selectedRoleFilter == 'Активист') return roles.contains(GroupRole.activist);
                    if (_selectedRoleFilter == 'Староста') return roles.contains(GroupRole.head);
                    if (_selectedRoleFilter == 'Заместитель') return roles.contains(GroupRole.deputy);
                    if (_selectedRoleFilter == 'Студент') return roles.every((r) => r == GroupRole.student);
                    return true;
                  }).toList();
                }

                if (_sortBy == 'points') {
                  users.sort((a, b) => (b['unionPoints'] as int).compareTo(a['unionPoints'] as int));
                } else {
                  users.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
                }

                if (users.isEmpty) return const Center(child: Text('Пользователи не найдены'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final user = users[i];
                    return _UserCard(
                      user: user,
                      onEditRoles: () => _showRoleEditor(context, user),
                      onEditPoints: () => _showPointsEditor(context, user),
                      onEditGroup: () => _showGroupEditor(context, user), // ✅ Новое
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

  // ✅ ДИАЛОГ СМЕНЫ ГРУППЫ ДЛЯ АДМИНА
  void _showGroupEditor(BuildContext context, Map<String, dynamic> user) {
    String? selectedDeptId = user['departmentId'];
    String? selectedGroup = user['group'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Группа: ${user['name']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Выбор института
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('departments').orderBy('shortName').snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const LinearProgressIndicator();
                      final depts = snap.data!.docs;
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Подразделение'),
                        value: selectedDeptId,
                        dropdownColor: Theme.of(context).cardColor,
                        items: depts.map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text((d.data() as Map<String, dynamic>?)?['shortName'] ?? d.id),
                        )).toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedDeptId = v;
                            selectedGroup = null; // сброс группы
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Выбор группы
                  if (selectedDeptId != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groups')
                          .where('departmentId', isEqualTo: selectedDeptId)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const LinearProgressIndicator();
                        final groups = snap.data!.docs.map((d) => d['name'] as String).toList();

                        if (groups.isEmpty) return const Text('Нет групп в этом подразделении');

                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Группа'),
                          value: groups.contains(selectedGroup) ? selectedGroup : null,
                          dropdownColor: Theme.of(context).cardColor,
                          items: groups.map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g),
                          )).toList(),
                          onChanged: (v) => setState(() => selectedGroup = v),
                        );
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () async {
                  if (selectedGroup == null || selectedDeptId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Выберите институт и группу'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  final deptDoc = await FirebaseFirestore.instance.collection('departments').doc(selectedDeptId).get();
                  final deptName = deptDoc.data()?['name'] ?? '';

                  await FirebaseFirestore.instance.collection('users').doc(user['uid']).update({
                    'group': selectedGroup,
                    'departmentId': selectedDeptId,
                    'institute': deptName,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Группа обновлена'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRoleEditor(BuildContext context, Map<String, dynamic> user) {
    final List<GroupRole> currentRoles = List.from(user['roles']);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Роли: ${user['name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: GroupRole.values.map((role) {
                    if (role == GroupRole.student) return const SizedBox.shrink();
                    return CheckboxListTile(
                      title: Text(role.title),
                      value: currentRoles.contains(role),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            currentRoles.add(role);
                          } else {
                            currentRoles.remove(role);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (currentRoles.isEmpty) currentRoles.add(GroupRole.student);

                    final updates = <String, dynamic>{
                      'roles': currentRoles.map((r) => r.key).toList(),
                    };

                    if (currentRoles.contains(GroupRole.head)) {
                      updates['groupRole'] = 'head';
                    } else if (currentRoles.contains(GroupRole.deputy)) {
                      updates['groupRole'] = 'deputy';
                    } else {
                      updates['groupRole'] = 'student';
                    }

                    // Глобальную роль меняем только при выдаче/снятии админа.
                    // Иначе «активист» молча сбрасывался бы до «студента».
                    final globalRole = (user['role'] ?? 'student').toString();
                    if (currentRoles.contains(GroupRole.admin)) {
                      updates['role'] = 'admin';
                    } else if (globalRole == 'admin') {
                      updates['role'] = 'student';
                    }

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user['uid'])
                        .update(updates);

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPointsEditor(BuildContext context, Map<String, dynamic> user) {
    final TextEditingController controller = TextEditingController(text: user['unionPoints'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Баллы: ${user['name']}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Количество баллов',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                final newPoints = int.tryParse(controller.text) ?? 0;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user['uid'])
                    .update({'unionPoints': newPoints});
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEditRoles;
  final VoidCallback onEditPoints;
  final VoidCallback onEditGroup; // ✅ Новый коллбэк

  const _UserCard({
    required this.user,
    required this.onEditRoles,
    required this.onEditPoints,
    required this.onEditGroup,
  });

  @override
  Widget build(BuildContext context) {
    final List<GroupRole> roles = user['roles'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'], style: Theme.of(context).textTheme.titleMedium),
                      Text('Группа: ${user['group']}', style: Theme.of(context).textTheme.bodySmall),
                      Text(user['institute'], style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onEditPoints,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: AppTheme.gold, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${user['unionPoints']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: roles.map((r) => Chip(
                label: Text(r.title, style: const TextStyle(fontSize: 10)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEditGroup,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Сменить группу'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onEditRoles,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Роли'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}