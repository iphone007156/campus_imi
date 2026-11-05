import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/app_ui.dart';

/// Жалобы студентов на сообщения в чатах групп.
/// Администратор может удалить сообщение или отклонить жалобу.
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  Future<void> _deleteMessage(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final data = doc.data();
    final groupId = (data['groupId'] ?? '').toString();
    final messageId = (data['messageId'] ?? '').toString();
    try {
      if (groupId.isNotEmpty && messageId.isNotEmpty) {
        await FirebaseFirestore.instance
            .doc('groups/$groupId/chat/$messageId')
            .delete();
      }
      await doc.reference.delete();
      messenger.showSnackBar(
        const SnackBar(content: Text('Сообщение удалено, жалоба закрыта')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось выполнить действие')),
      );
    }
  }

  Future<void> _dismiss(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await doc.reference.delete();
      messenger.showSnackBar(const SnackBar(content: Text('Жалоба закрыта')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось закрыть жалобу')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Жалобы')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const AppErrorState();
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.verified_outlined,
              title: 'Жалоб нет',
              message: 'Новые жалобы студентов появятся здесь',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final created = (data['createdAt'] as Timestamp?)?.toDate();
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppBadge(
                          (data['reason'] ?? 'Другое').toString(),
                          tone: AppTone.danger,
                        ),
                        if (created != null)
                          Text(
                            fmt.format(created),
                            style: TextStyle(
                              fontSize: 12,
                              color: appMutedColor(context),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (data['text'] ?? '').toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Группа: ${(data['groupId'] ?? '—').toString()}',
                      style: TextStyle(fontSize: 12, color: appMutedColor(context)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _dismiss(context, doc),
                            child: const Text('Отклонить'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _deleteMessage(context, doc),
                            child: const Text('Удалить сообщение'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
