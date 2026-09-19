import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
import 'event_participants_screen.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final EventService _eventService = EventService();
  final UserService _userService = UserService();

  String _filter = 'all';
  bool _onlyMyEvents = false;
  UserRole _role = UserRole.student;
  bool _isRoleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await _userService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        _role = role;
        _isRoleLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!_isRoleLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление мероприятиями'),
        actions: [
          if (_role == UserRole.admin)
            IconButton(
              icon: Icon(
                _onlyMyEvents ? Icons.person : Icons.person_outline,
                color: Colors.white,
              ),
              tooltip: _onlyMyEvents ? 'Показать все' : 'Только мои',
              onPressed: () {
                setState(() => _onlyMyEvents = !_onlyMyEvents);
              },
            ),
        ],
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          // Фильтры
          Container(
            color: AppTheme.cardWhite,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FilterChip(
                  label: 'Все',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                _FilterChip(
                  label: 'Активные',
                  selected: _filter == 'active',
                  onTap: () => setState(() => _filter = 'active'),
                ),
                _FilterChip(
                  label: 'Завершённые',
                  selected: _filter == 'finished',
                  onTap: () => setState(() => _filter = 'finished'),
                ),
              ],
            ),
          ),

          // Список
          Expanded(
            child: StreamBuilder<List<Event>>(
              stream: _eventService.getEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }

                var events = snapshot.data ?? [];

                if (_onlyMyEvents && currentUser != null) {
                  events = events
                      .where((e) => e.organizerId == currentUser.uid)
                      .toList();
                }

                if (_filter == 'active') {
                  events = events.where((e) => !e.isFinished).toList();
                } else if (_filter == 'finished') {
                  events = events.where((e) => e.isFinished).toList();
                }

                if (events.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, i) => _AdminEventCard(
                    event: events[i],
                    currentUserId: currentUser?.uid,
                    currentRole: _role,
                    onTap: () => _openEditor(events[i]),
                  ),
                );
              },
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
          const Icon(Icons.event_busy, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text(
            'Мероприятий не найдено',
            style: TextStyle(fontSize: 18, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            _onlyMyEvents
                ? 'У вас пока нет своих мероприятий'
                : _filter == 'active'
                ? 'Нет активных мероприятий'
                : _filter == 'finished'
                ? 'Нет завершённых мероприятий'
                : 'Создайте первое мероприятие',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditorScreen(event: event),
      ),
    );
  }
}

// ===== ФИЛЬТР-ЧИП =====
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryNavy : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textDark,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ===== КАРТОЧКА МЕРОПРИЯТИЯ ДЛЯ АДМИНА =====
class _AdminEventCard extends StatelessWidget {
  final Event event;
  final String? currentUserId;
  final UserRole currentRole;
  final VoidCallback onTap;

  const _AdminEventCard({
    required this.event,
    required this.currentUserId,
    required this.currentRole,
    required this.onTap,
  });

  bool get isMine => currentUserId == event.organizerId;
  bool get canManage => currentRole == UserRole.admin || isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canManage ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMine
                    ? AppTheme.accentBlue.withValues(alpha: 0.5)
                    : AppTheme.divider,
                width: isMine ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isMine)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ВАШЕ',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    _StatusBadge(event: event),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${event.date} • ${event.time}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.group,
                      label: '${event.participants.length}',
                      color: AppTheme.accentBlue,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.check_circle,
                      label: '${event.attended.length}',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.star,
                      label: '+${event.points}',
                      color: AppTheme.gold,
                    ),
                    const Spacer(),
                    if (canManage)
                      const Icon(Icons.edit,
                          size: 16, color: AppTheme.accentBlue),
                  ],
                ),
                if (event.organizer.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Организатор: ${event.organizer}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===== СТАТУС-БЕЙДЖ =====
class _StatusBadge extends StatelessWidget {
  final Event event;

  const _StatusBadge({required this.event});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    if (event.finalized) {
      color = Colors.green;
      label = 'Завершено';
      icon = Icons.check_circle;
    } else if (event.isFinished) {
      color = Colors.orange;
      label = 'Ожидает';
      icon = Icons.hourglass_bottom;
    } else {
      color = AppTheme.accentBlue;
      label = 'Активно';
      icon = Icons.play_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== МИНИ-СТАТ =====
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== РЕДАКТОР МЕРОПРИЯТИЯ =====
class EventEditorScreen extends StatefulWidget {
  final Event event;

  const EventEditorScreen({super.key, required this.event});

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final EventService _eventService = EventService();
  final UserService _userService = UserService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _locationController;
  late TextEditingController _pointsController;
  late TextEditingController _imageUrlController;
  late TextEditingController _endDateController;
  late TextEditingController _endTimeController;

  bool _isEditing = false;
  bool _isSaving = false;
  UserRole _role = UserRole.student;

  @override
  void initState() {
    super.initState();
    _loadRole();

    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController =
        TextEditingController(text: widget.event.description);
    _dateController = TextEditingController(text: widget.event.date);
    _timeController = TextEditingController(text: widget.event.time);
    _locationController = TextEditingController(text: widget.event.location);
    _pointsController =
        TextEditingController(text: widget.event.points.toString());
    _imageUrlController = TextEditingController(text: widget.event.imageUrl);

    if (widget.event.endTime != null) {
      final dt = widget.event.endTime!;
      _endDateController = TextEditingController(
        text:
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}',
      );
      _endTimeController = TextEditingController(
        text:
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
      );
    } else {
      _endDateController = TextEditingController();
      _endTimeController = TextEditingController();
    }
  }

  Future<void> _loadRole() async {
    final role = await _userService.getCurrentUserRole();
    if (mounted) setState(() => _role = role);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _pointsController.dispose();
    _imageUrlController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      DateTime? endTime;
      try {
        final dateParts = _endDateController.text.trim().split('.');
        final timeParts = _endTimeController.text.trim().split(':');
        if (dateParts.length == 3 && timeParts.length == 2) {
          endTime = DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
        }
      } catch (e) {
        debugPrint('Ошибка: $e');
      }

      final points = int.tryParse(_pointsController.text.trim()) ??
          widget.event.points;

      if (_role == UserRole.activist && points > 20) {
        throw Exception('Активист может ставить не более 20 баллов');
      }

      final updatedEvent = widget.event.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _dateController.text.trim(),
        time: _timeController.text.trim(),
        location: _locationController.text.trim(),
        points: points,
        imageUrl: _imageUrlController.text.trim(),
        endTime: endTime,
      );

      await _eventService.updateEvent(updatedEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Изменения сохранены'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _finalizeEvent() async {
    final attendedCount = widget.event.attended.length;

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
            content: Text('✅ Мероприятие завершено'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить мероприятие?'),
        content: Text(
            'Мероприятие "${widget.event.title}" будет удалено навсегда.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _eventService.deleteEvent(widget.event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Мероприятие удалено'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование' : 'Мероприятие'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              tooltip: 'Сохранить',
              onPressed: _isSaving ? null : _saveChanges,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Редактировать',
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: _isEditing ? _buildEditMode() : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.event.imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.event.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: 16),

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
              Text(widget.event.title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              const SizedBox(height: 12),
              _InfoLine(icon: Icons.calendar_today, text: widget.event.date),
              _InfoLine(icon: Icons.access_time, text: widget.event.time),
              _InfoLine(icon: Icons.location_on, text: widget.event.location),
              _InfoLine(icon: Icons.person, text: widget.event.organizer),
              _InfoLine(
                  icon: Icons.star,
                  text: '${widget.event.points} баллов',
                  color: AppTheme.gold),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
              const Text('Описание',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
              const SizedBox(height: 8),
              Text(widget.event.description,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textDark, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: _BigStat(
                  icon: Icons.group,
                  value: '${widget.event.participants.length}',
                  label: 'Записались',
                  color: AppTheme.accentBlue,
                ),
              ),
              Container(width: 1, height: 50, color: AppTheme.divider),
              Expanded(
                child: _BigStat(
                  icon: Icons.check_circle,
                  value: '${widget.event.attended.length}',
                  label: 'Пришли',
                  color: Colors.green,
                ),
              ),
              Container(width: 1, height: 50, color: AppTheme.divider),
              Expanded(
                child: _BigStat(
                  icon: Icons.star,
                  value:
                  '+${widget.event.points * widget.event.attended.length}',
                  label: 'Баллов',
                  color: AppTheme.gold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EventParticipantsScreen(event: widget.event),
                ),
              );
            },
            icon: const Icon(Icons.people_outline),
            label: Text('Участники (${widget.event.participants.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (!widget.event.finalized)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _finalizeEvent,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Завершить и начислить баллы'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

        if (!widget.event.finalized) const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _deleteEvent,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Удалить мероприятие',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEditMode() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildField('Название', _titleController, Icons.title),
        const SizedBox(height: 12),
        _buildField('Описание', _descriptionController, Icons.description,
            maxLines: 4),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child:
            _buildField('Дата', _dateController, Icons.calendar_today),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField('Время', _timeController, Icons.access_time),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child:
            _buildField('До конца', _endDateController, Icons.event_busy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
                'Время', _endTimeController, Icons.timer_off),
          ),
        ]),
        const SizedBox(height: 12),
        _buildField('Место', _locationController, Icons.location_on),
        const SizedBox(height: 12),
        _buildField('Баллы', _pointsController, Icons.star,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _buildField('URL картинки', _imageUrlController, Icons.image),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _isEditing = false),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Отмена'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)
                  : const Text('Сохранить'),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, IconData icon,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// ===== ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ =====
class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoLine({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style:
              TextStyle(fontSize: 14, color: color ?? AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _BigStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}