import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/group_models.dart';
import '../services/group_service.dart';
import '../theme/app_theme.dart';

final _repo = GroupRepo.instance;
final _fmt = DateFormat('dd.MM.yyyy HH:mm');

class TasksEntry extends StatelessWidget {
  const TasksEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GroupAccess>(
      future: _repo.myAccess(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Задания')),
            body: Center(child: Text('Ошибка: ${snap.error}')),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final a = snap.data!;
        if (a.group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Задания')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'В профиле не указана группа. Укажите её в разделе «Профиль», и здесь появятся задания вашей группы.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              ),
            ),
          );
        }
        return TasksScreen(groupId: a.group!, roles: a.roles);
      },
    );
  }
}

class TasksScreen extends StatelessWidget {
  final String groupId;
  final List<GroupRole> roles;
  const TasksScreen({super.key, required this.groupId, required this.roles});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ Динамический фон
        appBar: AppBar(
          title: Text('Задания · $groupId'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 3.0, color: Colors.white),
              insets: EdgeInsets.symmetric(horizontal: 8.0),
            ),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Флудилка'),
              Tab(text: 'СРС'),
              Tab(text: 'Конспекты'),
              Tab(text: 'Объявления'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ChatTab(groupId: groupId, roles: roles),
            MaterialsTab(groupId: groupId, roles: roles, category: Cat.srs, withDeadline: true),
            MaterialsTab(groupId: groupId, roles: roles, category: Cat.lecture),
            MaterialsTab(groupId: groupId, roles: roles, category: Cat.announcement),
          ],
        ),
      ),
    );
  }
}

// ======================= ФЛУДИЛКА =======================

class ChatTab extends StatefulWidget {
  final String groupId;
  final List<GroupRole> roles;
  const ChatTab({super.key, required this.groupId, required this.roles});
  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> with AutomaticKeepAliveClientMixin {
  final _ctrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    await _repo.sendMessage(widget.groupId, t);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final canEdit = widget.roles.any((r) => r.canEdit);

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _repo.chat(widget.groupId),
            builder: (context, s) {
              if (s.hasError) return Center(child: Text('Ошибка: ${s.error}'));
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final msgs = s.data!;
              if (msgs.isEmpty) {
                return Center(
                  child: Text('Напишите первое сообщение',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                );
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final m = msgs[i];
                  final mine = m.authorId == _repo.uid;
                  final canDelete = mine || canEdit;
                  final cs = Theme.of(context).colorScheme;

                  // В темной теме цвета для своих/чужих сообщений
                  final bgColor = mine
                      ? (Theme.of(context).brightness == Brightness.dark
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.primaryContainer)
                      : (Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).cardColor
                      : cs.surfaceContainerHighest);

                  final textColor = mine
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : cs.onPrimaryContainer)
                      : (Theme.of(context).brightness == Brightness.dark ? Colors.white : cs.onSurface);

                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: GestureDetector(
                      onLongPress: canDelete
                          ? () => _repo.deleteMessage(widget.groupId, m.id)
                          : null,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.authorName,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: mine ? textColor.withValues(alpha: 0.7) : cs.primary
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(m.text, style: TextStyle(color: textColor)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Сообщение',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      fillColor: Theme.of(context).cardColor, // ✅
                    ),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ======================= СРС / КОНСПЕКТЫ / ОБЪЯВЛЕНИЯ =======================

Color deadlineColor(DateTime d) {
  final diff = d.difference(DateTime.now());
  if (diff.isNegative) return Colors.red;
  if (diff.inDays < 3) return Colors.orange;
  return Colors.green;
}

class MaterialsTab extends StatelessWidget {
  final String groupId;
  final List<GroupRole> roles;
  final String category;
  final bool withDeadline;

  const MaterialsTab({
    super.key,
    required this.groupId,
    required this.roles,
    required this.category,
    this.withDeadline = false,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = roles.any((r) => r.canEdit);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<MaterialItem>>(
        stream: _repo.materials(groupId, category),
        builder: (context, s) {
          if (s.hasError) return Center(child: Text('Ошибка: ${s.error}'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final items = s.data!;
          if (items.isEmpty) {
            return Center(
              child: Text(
                canEdit ? 'Пока пусто. Нажмите «Добавить»' : 'Пока ничего не добавлено',
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: items.length,
            itemBuilder: (_, i) => MaterialCard(item: items[i], groupId: groupId, canEdit: canEdit),
          );
        },
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).cardColor, // ✅
          builder: (_) => MaterialForm(groupId: groupId, category: category, withDeadline: withDeadline),
        ),
      )
          : null,
    );
  }
}

class MaterialCard extends StatelessWidget {
  final MaterialItem item;
  final String groupId;
  final bool canEdit;
  const MaterialCard({super.key, required this.item, required this.groupId, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    final subtitle = [item.discipline, item.teacher].where((e) => e.isNotEmpty).join(' — ');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).cardColor, // ✅
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.title, style: Theme.of(context).textTheme.titleMedium), // ✅
                ),
                if (canEdit)
                  PopupMenuButton<String>(
                    onSelected: (_) async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Удалить запись?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
                          ],
                        ),
                      );
                      if (ok == true) await _repo.deleteMaterial(groupId, item.id);
                    },
                    itemBuilder: (_) => const [PopupMenuItem(value: 'del', child: Text('Удалить'))],
                  ),
              ],
            ),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if (item.deadline != null) ...[
              const SizedBox(height: 8),
              Chip(
                avatar: Icon(Icons.timer_outlined, size: 18, color: deadlineColor(item.deadline!)),
                label: Text('Срок сдачи: ${_fmt.format(item.deadline!)}'),
                side: BorderSide(color: deadlineColor(item.deadline!)),
                visualDensity: VisualDensity.compact,
              ),
            ],
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item.description, style: Theme.of(context).textTheme.bodyMedium),
            ],
            for (final f in item.files)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(Icons.insert_drive_file_outlined, color: Theme.of(context).colorScheme.primary),
                title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                subtitle: Text('${(f.size / 1024 / 1024).toStringAsFixed(1)} МБ', style: Theme.of(context).textTheme.bodySmall),
                trailing: const Icon(Icons.download),
                onTap: () => launchUrl(Uri.parse(f.url), mode: LaunchMode.externalApplication),
              ),
            if (item.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${_fmt.format(item.createdAt!)}${item.edited ? ' · изменено' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MaterialForm extends StatefulWidget {
  final String groupId;
  final String category;
  final bool withDeadline;
  const MaterialForm({super.key, required this.groupId, required this.category, required this.withDeadline});
  @override
  State<MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends State<MaterialForm> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _discipline = TextEditingController();
  final _teacher = TextEditingController();
  DateTime? _deadline;
  List<PlatformFile> _files = [];
  bool _saving = false;

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 23, minute: 59));
    setState(() => _deadline = DateTime(d.year, d.month, d.day, t?.hour ?? 23, t?.minute ?? 59));
  }

  Future<void> _pickFiles() async {
    final r = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (r != null) setState(() => _files = r.files);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите заголовок')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.addMaterial(
        groupId: widget.groupId,
        category: widget.category,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        discipline: _discipline.text.trim(),
        teacher: _teacher.text.trim(),
        deadline: _deadline,
        files: _files,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Заголовок'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextField(
              controller: _discipline,
              decoration: const InputDecoration(labelText: 'Дисциплина'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextField(
              controller: _teacher,
              decoration: const InputDecoration(labelText: 'Преподаватель'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextField(
              controller: _desc,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Описание'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (widget.withDeadline)
              OutlinedButton.icon(
                onPressed: _pickDeadline,
                icon: const Icon(Icons.event),
                label: Text(_deadline == null ? 'Срок сдачи' : _fmt.format(_deadline!)),
              ),
            OutlinedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: Text(_files.isEmpty ? 'Прикрепить файлы' : 'Файлов: ${_files.length}'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Опубликовать'),
            ),
          ],
        ),
      ),
    );
  }
}