import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
import '../widgets/user_avatar.dart';

class EventParticipantsScreen extends StatefulWidget {
  final Event event;

  const EventParticipantsScreen({super.key, required this.event});

  @override
  State<EventParticipantsScreen> createState() => _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends State<EventParticipantsScreen> {
  final EventService _eventService = EventService();
  final UserService _userService = UserService();

  List<Map<String, dynamic>> _participantsData = [];
  bool _isLoading = true;
  bool _isBulkAction = false;
  UserRole _userRole = UserRole.student;

  bool get _canMark => _userRole == UserRole.admin || _userRole == UserRole.activist;
  bool get _isMine => FirebaseAuth.instance.currentUser?.uid == widget.event.organizerId;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadParticipantsData();
  }

  Future<void> _loadRole() async {
    final role = await _eventService.getCurrentUserRole();
    if (mounted) setState(() => _userRole = role);
  }

  Future<void> _loadParticipantsData() async {
    setState(() => _isLoading = true);

    try {
      final participants = widget.event.participants;
      if (participants.isEmpty) {
        setState(() { _participantsData = []; _isLoading = false; });
        return;
      }

      final usersMap = await _userService.getUsersByIds(participants);
      final List<Map<String, dynamic>> usersData = [];

      for (String uid in participants) {
        final data = usersMap[uid];
        if (data != null) {
          usersData.add({
            'uid': uid,
            'name': data['name'] ?? 'Неизвестный',
            'group': data['group'] ?? '—',
            'photoUrl': data['photoUrl'],
            'photoBase64': data['photoBase64'],
            'attended': widget.event.attended.contains(uid),
          });
        } else {
          usersData.add({
            'uid': uid,
            'name': 'Пользователь удалён',
            'group': '—',
            'photoUrl': '',
            'photoBase64': '',
            'attended': widget.event.attended.contains(uid),
          });
        }
      }

      setState(() { _participantsData = usersData; _isLoading = false; });
    } catch (e) {
      print('❌ Ошибка: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAttendance(String uid, bool currentAttended) async {
    if (!_canMark) return;
    try {
      if (currentAttended) {
        await _eventService.markNotAttended(widget.event.id, uid);
      } else {
        await _eventService.markAttended(widget.event.id, uid);
      }
      setState(() {
        final i = _participantsData.indexWhere((p) => p['uid'] == uid);
        if (i != -1) _participantsData[i]['attended'] = !currentAttended;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentAttended ? '❌ Отметка снята' : '✅ Отмечено (+${widget.event.points} баллов)'),
          backgroundColor: currentAttended ? Colors.orange : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _markAll() async {
    if (!_canMark || _participantsData.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отметить всех?'),
        content: Text('Все ${_participantsData.length} участников будут отмечены как пришедшие.\n\nБаллы (+${widget.event.points}) начислятся после завершения мероприятия.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Отметить всех')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isBulkAction = true);
    try {
      final allUids = _participantsData.map((p) => p['uid'] as String).toList();
      await _eventService.markAllAttended(widget.event.id, allUids);
      setState(() { for (var p in _participantsData) { p['attended'] = true; } _isBulkAction = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Отмечено ${allUids.length} участников'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      setState(() => _isBulkAction = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _unmarkAll() async {
    if (!_canMark || _participantsData.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Снять все отметки?'),
        content: Text('С всех ${_participantsData.length} участников будет снята отметка "пришёл".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('Снять все')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isBulkAction = true);
    try {
      final allUids = _participantsData.map((p) => p['uid'] as String).toList();
      await _eventService.unmarkAllAttended(widget.event.id, allUids);
      setState(() { for (var p in _participantsData) { p['attended'] = false; } _isBulkAction = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Снято ${allUids.length} отметок'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      setState(() => _isBulkAction = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendedCount = _participantsData.where((p) => p['attended'] == true).length;
    final allMarked = _participantsData.isNotEmpty && attendedCount == _participantsData.length;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Участники'),
        actions: [
          if (_canMark)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(_userRole.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(child: _StatBox(label: 'Записались', value: '${_participantsData.length}', color: Colors.white)),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(child: _StatBox(label: 'Пришли', value: '$attendedCount', color: Colors.greenAccent)),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(child: _StatBox(label: 'Баллов', value: '+${widget.event.points}', color: AppTheme.gold)),
              ],
            ),
          ),
          if (_canMark && _participantsData.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isBulkAction || allMarked ? null : _markAll,
                      icon: _isBulkAction ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.done_all, size: 18),
                      label: const Text('Отметить всех'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, foregroundColor: Colors.white, disabledBackgroundColor: theme.disabledColor,
                        padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isBulkAction || attendedCount == 0 ? null : _unmarkAll,
                      icon: const Icon(Icons.remove_done, size: 18),
                      label: const Text('Снять всех'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, foregroundColor: Colors.white, disabledBackgroundColor: theme.disabledColor,
                        padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!_canMark)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Только администратор или активист может отмечать посещение', style: TextStyle(fontSize: 12, color: Colors.orange))),
                ],
              ),
            ),
          if (_canMark && _userRole == UserRole.activist && !_isMine)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Вы можете отмечать только участников СВОИХ мероприятий', style: TextStyle(fontSize: 12, color: Colors.blue))),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _participantsData.isEmpty
                ? Center(child: Text('Пока никто не записался', style: TextStyle(color: theme.disabledColor)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _participantsData.length,
              itemBuilder: (context, i) {
                final p = _participantsData[i];
                final isAttended = p['attended'] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isAttended ? Colors.green : theme.dividerColor, width: isAttended ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      UserAvatar(customUserData: p, size: 46), // ✅
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.titleMedium?.color)),
                            Text(p['group'], style: TextStyle(fontSize: 12, color: theme.disabledColor)),
                          ],
                        ),
                      ),
                      if (_canMark)
                        Checkbox(value: isAttended, onChanged: _isBulkAction ? null : (_) => _toggleAttendance(p['uid'], isAttended), activeColor: Colors.green)
                      else
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isAttended ? Colors.green.withValues(alpha: 0.2) : theme.disabledColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAttended ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isAttended ? Colors.green : theme.disabledColor, size: 22,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
      ],
    );
  }
}