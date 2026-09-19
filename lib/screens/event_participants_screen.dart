import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
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
            final registeredAt = widget.event.getRegisteredAt(uid);
            final wasLate = widget.event.wasRegisteredAfterEnd(uid);

            usersData.add({
              'uid': uid,
              'name': data['name'] ?? 'Неизвестный',
              'group': data['group'] ?? '—',
              'email': data['email'] ?? '—',
              'photoBase64': data['photoBase64'],
              'attended': widget.event.attended.contains(uid),
              'registeredAt': registeredAt,
              'wasLate': wasLate,
            });
          }
        } catch (e) {
          print('Ошибка: $e');
        }
      }

      // Сортируем по времени записи (сначала самые ранние)
      usersData.sort((a, b) {
        final aTime = a['registeredAt'] as DateTime?;
        final bTime = b['registeredAt'] as DateTime?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });

      setState(() {
        _participantsData = usersData;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAttendance(String uid, bool attended) async {
    try {
      if (attended) {
        await _eventService.markAttended(widget.event.id, uid);
      } else {
        await _eventService.markNotAttended(widget.event.id, uid);
      }

      setState(() {
        final index = _participantsData.indexWhere((p) => p['uid'] == uid);
        if (index != -1) {
          _participantsData[index]['attended'] = attended;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            attended
                ? '✅ Отмечено (+${widget.event.points} баллов)'
                : '❌ Отметка снята',
          ),
          backgroundColor: attended ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _finalizeEvent() async {
    final attendedCount =
        _participantsData.where((p) => p['attended'] == true).length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить мероприятие?'),
        content: Text(
          'Баллы (+${widget.event.points}) будут начислены $attendedCount студентам.\n\n'
              'После этого запись/отписка станут недоступны.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _eventService.finalizeEvent(widget.event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Мероприятие завершено, баллы начислены'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdmin = currentUser?.uid == widget.event.organizerId;
    final attendedCount =
        _participantsData.where((p) => p['attended'] == true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Участники'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$attendedCount / ${_participantsData.length}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          // Инфо-плашка
          if (isAdmin && !widget.event.finalized)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFEDF4FF),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.accentBlue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Отмечайте студентов галочкой, которые пришли. Баллы начислятся только им.',
                      style:
                      TextStyle(fontSize: 12, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),

          if (widget.event.finalized)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.green.withValues(alpha: 0.1),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Мероприятие завершено. Баллы начислены.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Список
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _participantsData.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _participantsData.length,
              itemBuilder: (context, i) => _ParticipantCard(
                participant: _participantsData[i],
                isAdmin: isAdmin && !widget.event.finalized,
                endTime: widget.event.endTime,
                onToggleAttendance: (attended) =>
                    _toggleAttendance(
                        _participantsData[i]['uid'], attended),
              ),
            ),
          ),

          // Кнопка завершения
          if (isAdmin &&
              !widget.event.finalized &&
              _participantsData.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.cardWhite,
                border: Border(top: BorderSide(color: AppTheme.divider)),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _finalizeEvent,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      'Завершить и начислить баллы ($attendedCount)',
                      style: const TextStyle(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline,
              size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text('Нет участников',
              style: TextStyle(fontSize: 18, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Text('На мероприятие пока никто не записался',
              style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final Map<String, dynamic> participant;
  final bool isAdmin;
  final DateTime? endTime;
  final Function(bool) onToggleAttendance;

  const _ParticipantCard({
    required this.participant,
    required this.isAdmin,
    required this.endTime,
    required this.onToggleAttendance,
  });

  ImageProvider? _getImageFromBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(base64String));
    } catch (e) {
      return null;
    }
  }

  String _formatRegisteredAt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = _getImageFromBase64(participant['photoBase64']);
    final isAttended = participant['attended'] == true;
    final registeredAt = participant['registeredAt'] as DateTime?;
    final wasLate = participant['wasLate'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isAttended
            ? Colors.green.withValues(alpha: 0.05)
            : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: wasLate
                  ? Colors.red
                  : (isAttended ? Colors.green : AppTheme.divider),
              width: (isAttended || wasLate) ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Аватар
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.lightBlue,
                  image: photoProvider != null
                      ? DecorationImage(
                      image: photoProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: photoProvider == null
                    ? const Icon(Icons.person,
                    color: AppTheme.accentBlue, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),

              // Инфо
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            participant['name'] ?? 'Неизвестный',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        // Красный значок "поздно"
                        if (wasLate)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    size: 11, color: Colors.red),
                                SizedBox(width: 3),
                                Text(
                                  'Поздно',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.groups_outlined,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(participant['group'] ?? '—',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // ✅ Время записи
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: wasLate ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Записался: ${_formatRegisteredAt(registeredAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: wasLate ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Чекбокс
              if (isAdmin)
                Checkbox(
                  value: isAttended,
                  onChanged: (value) => onToggleAttendance(value ?? false),
                  activeColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                )
              else if (isAttended)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('Пришёл',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}