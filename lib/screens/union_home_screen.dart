import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
import 'add_event_screen.dart';
import 'event_detail_screen.dart';

ImageProvider? getImageFromBase64(String? base64String) {
  if (base64String == null || base64String.isEmpty) return null;
  try {
    return MemoryImage(base64Decode(base64String));
  } catch (e) {
    return null;
  }
}

class UnionHomeScreen extends StatefulWidget {
  const UnionHomeScreen({super.key});

  @override
  State<UnionHomeScreen> createState() => _UnionHomeScreenState();
}

class _UnionHomeScreenState extends State<UnionHomeScreen> {
  final EventService _eventService = EventService();
  final UserService _userService = UserService();

  int _totalPoints = 0;
  bool _isLoadingPoints = true;
  String _userName = 'Активист';
  String _userGroup = 'Группа';
  String _userPosition = 'Студент';
  String? _userPhotoBase64;
  UserRole _currentRole = UserRole.student;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserPoints();
    _loadUserRole();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _userName = data['name'] ?? 'Активист';
          _userGroup = data['group'] ?? 'Группа';
          _userPosition = data['unionPosition'] ?? 'Студент';
          _userPhotoBase64 = data['photoBase64'];
        });
      }
    } catch (e) {
      debugPrint('Ошибка: $e');
    }
  }

  Future<void> _loadUserRole() async {
    final role = await _userService.getCurrentUserRole();
    if (mounted) setState(() => _currentRole = role);
  }

  Future<void> _loadUserPoints() async {
    final points = await _eventService.getUserTotalPoints();
    if (mounted) {
      setState(() {
        _totalPoints = points;
        _isLoadingPoints = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = getImageFromBase64(_userPhotoBase64);
    final canCreate = _currentRole.canCreateEvents;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Профсоюз'),
        actions: [
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _navigateToAddEvent(),
              tooltip: 'Создать мероприятие',
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _UserProfileCard(
              userName: _userName,
              userGroup: _userGroup,
              userPosition: _userPosition,
              points: _totalPoints,
              isLoading: _isLoadingPoints,
              photoProvider: photoProvider,
              role: _currentRole,
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'МЕРОПРИЯТИЯ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          StreamBuilder<List<Event>>(
            stream: _eventService.getEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Ошибка: ${snapshot.error}')),
                );
              }

              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_outlined,
                            size: 48, color: AppTheme.textMuted),
                        SizedBox(height: 16),
                        Text('Мероприятий пока нет',
                            style: TextStyle(
                                fontSize: 16, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final event = events[index];
                    return _EventCard(
                      event: event,
                      onTap: () => _navigateToEventDetail(event),
                    );
                  },
                  childCount: events.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _navigateToAddEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEventScreen()),
    ).then((_) => _loadUserPoints());
  }

  void _navigateToEventDetail(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    ).then((_) => _loadUserPoints());
  }
}

// ===== КАРТОЧКА ПОЛЬЗОВАТЕЛЯ =====
class _UserProfileCard extends StatelessWidget {
  final String userName;
  final String userGroup;
  final String userPosition;
  final int points;
  final bool isLoading;
  final ImageProvider? photoProvider;
  final UserRole role;

  const _UserProfileCard({
    required this.userName,
    required this.userGroup,
    required this.userPosition,
    required this.points,
    required this.isLoading,
    required this.role,
    this.photoProvider,
  });

  Color get _roleColor {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.activist:
        return AppTheme.gold;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryNavy, Color(0xFF3D6FA3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 2),
              image: photoProvider != null
                  ? DecorationImage(image: photoProvider!, fit: BoxFit.cover)
                  : null,
            ),
            child: photoProvider == null
                ? const Icon(Icons.person, color: Colors.white, size: 36)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$userGroup • $userPosition',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: AppTheme.gold, size: 16),
                          const SizedBox(width: 4),
                          isLoading
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                              : Text(
                            '$points баллов',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (role != UserRole.student)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _roleColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _roleColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          role.label,
                          style: TextStyle(
                            color: _roleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== КАРТОЧКА МЕРОПРИЯТИЯ =====
class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  // ✅ Оптимизированное построение картинки
  Widget _buildEventImage() {
    // 1. URL — оптимизированный Image.network
    if (event.imageUrl.isNotEmpty) {
      return Image.network(
        event.imageUrl,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        cacheWidth: 200,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 80,
            height: 80,
            color: AppTheme.lightBlue,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accentBlue,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (_, __, ___) => Container(
          width: 80,
          height: 80,
          color: AppTheme.lightBlue,
          child: const Icon(Icons.event,
              color: AppTheme.accentBlue, size: 32),
        ),
      );
    }

    // 2. Base64
    if (event.imageBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(event.imageBase64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          errorBuilder: (_, __, ___) => Container(
            width: 80,
            height: 80,
            color: AppTheme.lightBlue,
            child: const Icon(Icons.event,
                color: AppTheme.accentBlue, size: 32),
          ),
        );
      } catch (e) {
        return Container(
          width: 80,
          height: 80,
          color: AppTheme.lightBlue,
          child: const Icon(Icons.event,
              color: AppTheme.accentBlue, size: 32),
        );
      }
    }

    // 3. Иконка (если нет ни URL, ни Base64)
    return Container(
      width: 80,
      height: 80,
      color: AppTheme.lightBlue,
      child: const Icon(
        Icons.event,
        color: AppTheme.accentBlue,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Картинка 80×80
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: _buildEventImage(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (event.finalized)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Завершено',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            event.date,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.access_time,
                              size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            event.time,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    color: AppTheme.gold, size: 12),
                                const SizedBox(width: 3),
                                Text(
                                  '+${event.points}',
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${event.participants.length} участ.',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}