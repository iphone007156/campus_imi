import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // Оставляем только convert, убираем typed_data
import '../theme/app_theme.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventParticipantsScreen extends StatefulWidget {
  final Event event;

  const EventParticipantsScreen({super.key, required this.event});

  @override
  State<EventParticipantsScreen> createState() =>
      _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends State<EventParticipantsScreen> {
  final EventService _eventService = EventService();
  List<Map<String, dynamic>> _participantsData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipantsData();
  }

  Future<void> _loadParticipantsData() async {
    setState(() => _isLoading = true);

    try {
      final participants = widget.event.participants;
      final List<Map<String, dynamic>> usersData = [];

      for (String uid in participants) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            usersData.add({
              'uid': uid,
              'name': data['name'] ?? 'Неизвестный',
              'group': data['group'] ?? 'Группа не указана',
              'email': data['email'] ?? '—',
              'phone': data['phone'] ?? '—',
              'photoBase64': data['photoBase64'],
            });
          } else {
            usersData.add({
              'uid': uid,
              'name': 'Пользователь удалён',
              'group': '—',
              'email': '—',
              'phone': '—',
              'photoBase64': '',
            });
          }
        } catch (e) {
          print('Ошибка загрузки участника $uid: $e');
        }
      }

      setState(() {
        _participantsData = usersData;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки участников: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeParticipant(String uid) async {
    try {
      await _eventService.leaveEvent(widget.event.id);
      setState(() {
        _participantsData.removeWhere((p) => p['uid'] == uid);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Участник удалён из мероприятия'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdmin = currentUser?.uid == widget.event.organizerId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Участники: ${widget.event.title}'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_participantsData.length} чел.',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _participantsData.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Нет участников',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'На мероприятие пока никто не записался',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _participantsData.length,
        itemBuilder: (context, index) {
          final participant = _participantsData[index];
          return _ParticipantCard(
            participant: participant,
            isAdmin: isAdmin,
            onRemove: () => _removeParticipant(participant['uid']),
          );
        },
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final Map<String, dynamic> participant;
  final bool isAdmin;
  final VoidCallback onRemove;

  const _ParticipantCard({
    required this.participant,
    required this.isAdmin,
    required this.onRemove,
  });

  ImageProvider? _getImageFromBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = _getImageFromBase64(participant['photoBase64']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.lightBlue,
                  image: photoProvider != null
                      ? DecorationImage(
                    image: photoProvider,
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: photoProvider == null
                    ? const Icon(Icons.person,
                    color: AppTheme.accentBlue, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant['name'] ?? 'Неизвестный',
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
                          participant['group'] ?? 'Группа не указана',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
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
                            participant['email'] ?? '—',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          participant['phone'] ?? '—',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                    size: 28,
                  ),
                  onPressed: () => _showRemoveDialog(context),
                  tooltip: 'Удалить участника',
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить участника'),
        content: Text(
          'Вы уверены, что хотите удалить ${participant['name']} из мероприятия?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}