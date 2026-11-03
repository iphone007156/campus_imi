import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
import '../widgets/user_avatar.dart';
import 'add_event_screen.dart';
import 'event_detail_screen.dart';

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
  UserRole _currentRole = UserRole.student;

  String? _userDeptId;
  bool _showOnlyMyDept = true;

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
          _userDeptId = data['departmentId'];
          if (_userDeptId == null) _showOnlyMyDept = false;
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
    final canCreate = _currentRole.canCreateEvents;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              role: _currentRole,
            ),
          ),
          if (_userDeptId != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showOnlyMyDept ? 'Только мое подразделение' : 'Все мероприятия',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Switch(
                      value: _showOnlyMyDept,
                      onChanged: (v) => setState(() => _showOnlyMyDept = v),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppTheme.s16, AppTheme.s20, AppTheme.s16, AppTheme.s8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'МЕРОПРИЯТИЯ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          StreamBuilder<List<Event>>(
            stream: _eventService.getEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Ошибка: ${snapshot.error}')));
              }

              var events = snapshot.data ?? [];
              if (_showOnlyMyDept && _userDeptId != null) {
                events = events.where((e) => e.departmentId == _userDeptId || e.departmentId.isEmpty).toList();
              }

              if (events.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_outlined, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(height: 16),
                        Text(
                          _showOnlyMyDept ? 'Мероприятий для вашего подразделения пока нет' : 'Мероприятий пока нет',
                          style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                          textAlign: TextAlign.center,
                        ),
                        if (_showOnlyMyDept) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() => _showOnlyMyDept = false),
                            child: const Text('Показать все мероприятия'),
                          ),
                        ],
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
          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.s24)),
        ],
      ),
    );
  }

  void _navigateToAddEvent() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEventScreen())).then((_) => _loadUserPoints());
  }

  void _navigateToEventDetail(Event event) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))).then((_) => _loadUserPoints());
  }
}

class _UserProfileCard extends StatelessWidget {
  final String userName;
  final String userGroup;
  final String userPosition;
  final int points;
  final bool isLoading;
  final UserRole role;

  const _UserProfileCard({
    required this.userName,
    required this.userGroup,
    required this.userPosition,
    required this.points,
    required this.isLoading,
    required this.role,
  });

  Color get _roleColor {
    switch (role) {
      case UserRole.admin: return Colors.red;
      case UserRole.activist: return AppTheme.gold;
      default: return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.s16),
      padding: const EdgeInsets.all(AppTheme.s20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryNavy, Color(0xFF2A4A7F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(
                userId: FirebaseAuth.instance.currentUser?.uid,
                size: 64,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                icon: Icons.person,
              ),
              const SizedBox(width: AppTheme.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('$userGroup • $userPosition', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.s20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.s16, vertical: AppTheme.s12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: AppTheme.gold, size: 20),
                      const SizedBox(width: AppTheme.s8),
                      isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('$points', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 4),
                      const Text('баллов', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              if (role != UserRole.student) ...[
                const SizedBox(width: AppTheme.s12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.s12, vertical: AppTheme.s12),
                  decoration: BoxDecoration(color: _roleColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppTheme.radiusMd), border: Border.all(color: _roleColor.withValues(alpha: 0.5))),
                  child: Text(role.label, style: TextStyle(color: _roleColor, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  Widget _buildEventImage() {
    if (event.imageUrl.isNotEmpty) {
      return Image.network(
        event.imageUrl,
        fit: BoxFit.contain, // ✅ Не обрезаем
        width: 100,
        height: 100,
        cacheWidth: 200,
        errorBuilder: (_, __, ___) => _buildBase64OrPlaceholder(),
      );
    }
    return _buildBase64OrPlaceholder();
  }

  Widget _buildBase64OrPlaceholder() {
    if (event.imageBase64.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(event.imageBase64),
          fit: BoxFit.contain, // ✅ Не обрезаем
          width: 100,
          height: 100,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {}
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      height: 100,
      color: AppTheme.lightBlue,
      child: const Icon(Icons.event, color: AppTheme.accentBlue, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.s16, vertical: 6),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppTheme.radiusMd), boxShadow: AppTheme.shadowSoft),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: SizedBox(width: 100, height: 100, child: _buildEventImage()),
                ),
                const SizedBox(width: AppTheme.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(event.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis)),
                          if (event.finalized)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                              child: const Text('Завершено', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.s4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Text(event.date, style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Text(event.time, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: AppTheme.s4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Expanded(child: Text(event.location, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: AppTheme.s8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: AppTheme.gold, size: 12),
                                const SizedBox(width: 3),
                                Text('+${event.points}', style: const TextStyle(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${event.participants.length} участ.', style: Theme.of(context).textTheme.bodySmall),
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