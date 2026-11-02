import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/department_model.dart';

class AdminGroupsScreen extends StatefulWidget {
  const AdminGroupsScreen({super.key});

  @override
  State<AdminGroupsScreen> createState() => _AdminGroupsScreenState();
}

class _AdminGroupsScreenState extends State<AdminGroupsScreen> {
  final _groupController = TextEditingController();
  String? _selectedDeptId;
  bool _isAdding = false;
  bool _isSyncing = false;

  Future<void> _addGroup() async {
    final name = _groupController.text.trim();
    if (name.isEmpty || _selectedDeptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя группы и выберите подразделение'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      await FirebaseFirestore.instance.collection('groups').doc(name).set({
        'name': name,
        'departmentId': _selectedDeptId, // ✅ Привязка к ID
      }, SetOptions(merge: true));

      _groupController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Группа добавлена'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _syncFromLessons() async {
    setState(() => _isSyncing = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('lessons').get();
      final Set<String> uniqueGroups = {};
      for (var doc in snapshot.docs) {
        final groupName = doc.data()['group'] as String?;
        if (groupName != null && groupName.isNotEmpty) uniqueGroups.add(groupName);
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (String groupName in uniqueGroups) {
        final docRef = FirebaseFirestore.instance.collection('groups').doc(groupName);
        batch.set(docRef, {'name': groupName}, SetOptions(merge: true));
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Синхронизировано ${uniqueGroups.length} групп'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showEditGroupDialog(String currentName, String? currentDeptId) {
    final nameCtrl = TextEditingController(text: currentName);
    String? newDeptId = currentDeptId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Редактировать группу'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Название группы'),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('departments').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final depts = snapshot.data?.docs.map((d) => Department.fromMap(d.id, d.data() as Map<String, dynamic>)).toList() ?? [];
                    final bool isValueValid = depts.any((d) => d.id == newDeptId);

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Подразделение'),
                      value: isValueValid ? newDeptId : null,
                      dropdownColor: Theme.of(context).cardColor,
                      items: depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.shortName))).toList(),
                      onChanged: (v) => setState(() => newDeptId = v),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  if (newName.isEmpty) return;

                  if (newName != currentName) {
                    await FirebaseFirestore.instance.collection('groups').doc(currentName).delete();
                  }

                  await FirebaseFirestore.instance.collection('groups').doc(newName).set({
                    'name': newName,
                    'departmentId': newDeptId,
                  }, SetOptions(merge: true));

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление группами')),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _groupController,
                        decoration: const InputDecoration(labelText: 'Название (напр. ИМИ-Б-ФИИТ-25)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isAdding ? null : _addGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      child: _isAdding
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Добавить', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('departments').snapshots(),
                  builder: (context, snapshot) {
                    final depts = snapshot.data?.docs.map((d) => Department.fromMap(d.id, d.data() as Map<String, dynamic>)).toList() ?? [];
                    final bool isValueValid = depts.any((d) => d.id == _selectedDeptId);

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Подразделение', border: OutlineInputBorder()),
                      value: isValueValid ? _selectedDeptId : null,
                      dropdownColor: Theme.of(context).cardColor,
                      items: depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.shortName))).toList(),
                      onChanged: (v) => setState(() => _selectedDeptId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSyncing ? null : _syncFromLessons,
                    icon: _isSyncing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync),
                    label: Text(_isSyncing ? 'Синхронизация...' : 'Синхронизировать из расписания'),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('groups').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('Групп пока нет.'));

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final groupName = data['name'] ?? 'Без имени';
                    final deptId = data['departmentId'];

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Icon(Icons.groups, color: Theme.of(context).colorScheme.primary, size: 20),
                      ),
                      title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: deptId != null
                          ? FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('departments').doc(deptId).get(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) return const Text('Загрузка...');
                          if (snap.hasData && snap.data!.exists) {
                            final deptData = snap.data!.data() as Map<String, dynamic>;
                            return Text('Подразделение: ${deptData['shortName'] ?? deptData['name']}', maxLines: 1, overflow: TextOverflow.ellipsis);
                          }
                          return Text('Подразделение: $deptId', maxLines: 1, overflow: TextOverflow.ellipsis);
                        },
                      )
                          : const Text('Подразделение не указано'),
                      trailing: SizedBox(
                        width: 96,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppTheme.accentBlue),
                              onPressed: () => _showEditGroupDialog(groupName, deptId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('groups').doc(docs[i].id).delete();
                              },
                            ),
                          ],
                        ),
                      ),
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