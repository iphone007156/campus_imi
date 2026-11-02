// lib/screens/support_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ───────────────────────── Строки ─────────────────────────

class _S {
  static const title = 'Техническая поддержка';
  static const tabNew = 'Новое';
  static const tabMine = 'Мои';
  static const tabAll = 'Все';
  static const intro = 'Расскажи, что случилось, и мы ответим в приложении.';
  static const topic = 'Тема';
  static const description = 'Описание';
  static const descriptionHint = 'Что делал, что ожидал и что получилось';
  static const send = 'Отправить';
  static const sending = 'Отправка...';
  static const empty = 'Обращений пока нет';
  static const needLogin = 'Нужно войти в аккаунт';
  static const sent = 'Обращение отправлено';
  static const supportReply = 'Ответ поддержки';
  static const autoReplyLabel = 'Автоответ';
  static const pending = 'отправляется...';
  static const defaultCategory = 'Обращение';

  static const autoReply =
      'Спасибо за обращение! Мы получили его и ответим в ближайшее время. '
      'Обычно это занимает 1–2 рабочих дня.';

  static const keyNew = 'new';
  static const keyProgress = 'in_progress';
  static const keyDone = 'resolved';

  static const errNetwork = 'Нет соединения. Проверь интернет';
  static const errDenied = 'Нет прав. Войди заново';
  static const errUnknown = 'Не удалось. Попробуй ещё раз позже';
  static const errLoad = 'Не удалось загрузить обращения';

  static const statusNew = 'Новое';
  static const statusProgress = 'В работе';
  static const statusDone = 'Решено';

  static const minLength = 10;
  static const maxLength = 1000;

  static String get tooShort =>
      'Опиши проблему подробнее (минимум $minLength символов)';

  static const reply = 'Ответ';
  static const replyHint = 'Напиши ответ студенту';
  static const sendReply = 'Отправить ответ';
  static const markInProgress = 'В работу';
  static const markResolved = 'Решено';
  static const replySent = 'Ответ отправлен';
}

const _categories = [
  'Ошибка в приложении',
  'Расписание',
  'Карта корпуса',
  'Вход и аккаунт',
  'Предложение по улучшению',
  'Другое',
];

String _errorText(Object e) {
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return _S.errDenied;
      case 'unavailable':
      case 'deadline-exceeded':
        return _S.errNetwork;
    }
  }
  return _S.errUnknown;
}

// ───────────────────────── Экран ─────────────────────────

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(_S.title)),
        body: const Center(child: Text(_S.needLogin)),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, roleSnap) {
        final role = roleSnap.data?.data()?['role'];
        final isAdmin = role == 'admin';

        return DefaultTabController(
          length: isAdmin ? 3 : 2,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text(_S.title),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      // ✅ Классический вид (без белых овалов)
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(width: 3.0, color: Colors.white),
                        insets: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: _S.tabNew),
                        Tab(text: _S.tabMine),
                        if (isAdmin) Tab(text: _S.tabAll),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: TabBarView(
              children: [
                const _NewTicketTab(),
                const _MyTicketsTab(),
                if (isAdmin) const _AllTicketsTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────── Новое ─────────────────────────

class _NewTicketTab extends StatefulWidget {
  const _NewTicketTab();

  @override
  State<_NewTicketTab> createState() => _NewTicketTabState();
}

class _NewTicketTabState extends State<_NewTicketTab> {
  final _text = TextEditingController();
  String _category = _categories.first;
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _text.text.trim();
    if (message.length < _S.minLength) return _snack(_S.tooShort);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _snack(_S.needLogin);

    setState(() => _sending = true);
    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = profile.data() ?? {};

      await FirebaseFirestore.instance.collection('support_tickets').add({
        'uid': user.uid,
        'userName': (data['name'] ?? '').toString(),
        'group': (data['group'] ?? '').toString(),
        'category': _category,
        'message': message,
        'status': _S.keyNew,
        'createdAt': FieldValue.serverTimestamp(),
        'reply': _S.autoReply,
        'repliedAt': FieldValue.serverTimestamp(),
        'autoReply': true,
      });

      if (!mounted) return;
      _text.clear();
      FocusScope.of(context).unfocus();
      _snack(_S.sent);
      DefaultTabController.of(context).animateTo(1);
    } catch (e) {
      if (!mounted) return;
      _snack(_errorText(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.s16),
      children: [
        Text(_S.intro, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppTheme.s16),
        InputDecorator(
          decoration: const InputDecoration(labelText: _S.topic),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              isDense: true,
              dropdownColor: Theme.of(context).cardColor,
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.s12),
        TextField(
          controller: _text,
          maxLines: 8,
          maxLength: _S.maxLength,
          decoration: const InputDecoration(
            labelText: _S.description,
            hintText: _S.descriptionHint,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppTheme.s12),
        FilledButton.icon(
          onPressed: _sending ? null : _send,
          icon: _sending
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              : const Icon(Icons.send),
          label: Text(_sending ? _S.sending : _S.send),
        ),
      ],
    );
  }
}

// ───────────────────────── Мои ─────────────────────────

class _MyTicketsTab extends StatelessWidget {
  const _MyTicketsTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text(_S.needLogin));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('support_tickets')
          .where('uid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text(_S.errLoad));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs.toList()..sort(_sortByCreatedAtDesc);

        if (docs.isEmpty) {
          return Center(
            child: Text(_S.empty,
                style: Theme.of(context).textTheme.bodyMedium),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppTheme.s16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.s12),
          itemBuilder: (_, i) => _TicketCard(
            data: docs[i].data(),
            id: docs[i].id,
            isAdmin: false,
          ),
        );
      },
    );
  }
}

// ───────────────────────── Все ─────────────────────────

class _AllTicketsTab extends StatelessWidget {
  const _AllTicketsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('support_tickets')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text(_S.errLoad));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(_S.empty,
                style: Theme.of(context).textTheme.bodyMedium),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppTheme.s16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.s12),
          itemBuilder: (_, i) => _TicketCard(
            data: docs[i].data(),
            id: docs[i].id,
            isAdmin: true,
          ),
        );
      },
    );
  }
}

int _sortByCreatedAtDesc(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
    ) {
  final now = DateTime.now().millisecondsSinceEpoch;
  int key(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      (d.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? now;
  return key(b).compareTo(key(a));
}

// ───────────────────────── Карточка ─────────────────────────

class _TicketCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String id;
  final bool isAdmin;

  const _TicketCard({
    required this.data,
    required this.id,
    required this.isAdmin,
  });

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  final _replyController = TextEditingController();
  bool _sendingReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  static String _date(Timestamp? ts) {
    if (ts == null) return _S.pending;
    final d = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _sendReply() async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty) return;

    setState(() => _sendingReply = true);
    try {
      await FirebaseFirestore.instance
          .collection('support_tickets')
          .doc(widget.id)
          .update({
        'reply': reply,
        'repliedAt': FieldValue.serverTimestamp(),
        'status': _S.keyDone,
        'autoReply': false,
      });
      if (!mounted) return;
      _replyController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(_S.replySent),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorText(e)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingReply = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('support_tickets')
          .doc(widget.id)
          .update({'status': status});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorText(e)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.data;
    final status = (t['status'] ?? _S.keyNew).toString();
    final (label, color) = switch (status) {
      _S.keyProgress => (_S.statusProgress, AppTheme.accent),
      _S.keyDone => (_S.statusDone, const Color(0xFF22A06B)),
      _ => (_S.statusNew, AppTheme.accentBlue),
    };
    final reply = (t['reply'] ?? '').toString();
    final isAuto = (t['autoReply'] ?? false) == true;

    return Container(
      padding: const EdgeInsets.all(AppTheme.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Категория + статус
          Row(
            children: [
              Expanded(
                child: Text(
                  (t['category'] ?? _S.defaultCategory).toString(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (widget.isAdmin)
            Text(
              '${t['userName'] ?? ''} • ${t['group'] ?? ''} • '
                  '${_date(t['createdAt'] as Timestamp?)}',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Text(
              _date(t['createdAt'] as Timestamp?),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: AppTheme.s12),
          Text(
            (t['message'] ?? '').toString(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (reply.isNotEmpty) ...[
            const SizedBox(height: AppTheme.s12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.s12),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isAuto ? _S.autoReplyLabel : _S.supportReply,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      if (isAuto) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.smart_toy_outlined,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(reply, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
          if (widget.isAdmin) ...[
            const SizedBox(height: AppTheme.s12),
            Row(
              children: [
                if (status == _S.keyNew)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.s16),
                    ),
                    onPressed: () => _updateStatus(_S.keyProgress),
                    child: const Text(_S.markInProgress),
                  ),
                if (status == _S.keyProgress)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.s16),
                    ),
                    onPressed: () => _updateStatus(_S.keyDone),
                    child: const Text(_S.markResolved),
                  ),
              ],
            ),
            if (reply.isEmpty || isAuto) ...[
              const SizedBox(height: AppTheme.s12),
              TextField(
                controller: _replyController,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: _S.reply,
                  hintText: _S.replyHint,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppTheme.s8),
              FilledButton.icon(
                onPressed: _sendingReply ? null : _sendReply,
                icon: _sendingReply
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.reply),
                label: const Text(_S.sendReply),
              ),
            ],
          ],
        ],
      ),
    );
  }
}