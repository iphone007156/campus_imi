import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'event_participants_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();
  bool _isParticipant = false;
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkParticipation();
    _checkAdmin();
  }

  Future<void> _checkParticipation() async {
    final isParticipant = await _eventService.isUserParticipant(widget.event.id);
    setState(() {
      _isParticipant = isParticipant;
      _isLoading = false;
    });
  }

  void _checkAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isAdmin = user?.uid == widget.event.organizerId;
    });
  }

  Future<void> _toggleParticipation() async {
    setState(() => _isLoading = true);

    try {
      if (_isParticipant) {
        await _eventService.leaveEvent(widget.event.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы отписались от мероприятия'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await _eventService.joinEvent(widget.event.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Вы записались! +${widget.event.points} баллов 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      setState(() => _isParticipant = !_isParticipant);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        actions: [
          // Кнопка удаления мероприятия (только для админа)
          if (_isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _showDeleteEventDialog();
              },
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Удалить мероприятие', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение
            if (widget.event.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.event.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: AppTheme.lightBlue,
                    child: const Icon(Icons.image_not_supported, size: 48, color: AppTheme.textMuted),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Основная информация
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.event.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.gold),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppTheme.gold, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '+${widget.event.points}',
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(icon: Icons.calendar_today, text: widget.event.date),
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.access_time, text: widget.event.time),
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.location_on, text: widget.event.location),
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.person, text: 'Организатор: ${widget.event.organizer}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.group, size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        'Участников: ${widget.event.participants.length}',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Описание
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'О мероприятии',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Кнопка "Посмотреть участников" (для всех)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.event.participants.isEmpty
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventParticipantsScreen(event: widget.event),
                    ),
                  );
                },
                icon: const Icon(Icons.people_outline),
                label: Text(
                  widget.event.participants.isEmpty
                      ? 'Нет участников'
                      : 'Посмотреть всех участников (${widget.event.participants.length})',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: widget.event.participants.isEmpty
                        ? AppTheme.textMuted
                        : AppTheme.accentBlue,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Кнопка записи/отписки (для студентов, не для админа)
            if (!_isAdmin)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _toggleParticipation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isParticipant ? Colors.red : AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    _isParticipant ? 'Отписаться' : 'Записаться на мероприятие',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Диалог удаления мероприятия
  void _showDeleteEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить мероприятие'),
        content: const Text('Вы уверены, что хотите удалить это мероприятие? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _eventService.deleteEvent(widget.event.id);
                if (mounted) {
                  Navigator.pop(context); // Закрыть диалог
                  Navigator.pop(context, true); // Закрыть экран деталей
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Ошибка удаления: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

// --- Вспомогательный виджет ---
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
          ),
        ),
      ],
    );
  }
}