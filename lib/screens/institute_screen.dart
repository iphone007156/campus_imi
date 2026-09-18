import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InstituteItem {
  final IconData icon;
  final String label;
  final String subtitle;

  const InstituteItem({
    required this.icon,
    required this.label,
    required this.subtitle,
  });
}

class InstituteScreen extends StatelessWidget {
  const InstituteScreen({super.key});

  static const List<InstituteItem> _items = [
    InstituteItem(
      icon: Icons.history_edu_outlined,
      label: 'История ИМИ СВФУ',
      subtitle: 'Основан в 1956 году',
    ),
    InstituteItem(
      icon: Icons.newspaper_outlined,
      label: 'Новости',
      subtitle: 'Последние события',
    ),
    InstituteItem(
      icon: Icons.map_outlined,
      label: 'Карта',
      subtitle: 'Схема зданий',
    ),
    InstituteItem(
      icon: Icons.work_outline,
      label: 'Профессии',
      subtitle: 'Направления подготовки',
    ),
    InstituteItem(
      icon: Icons.people_outline,
      label: 'Профсоюз',
      subtitle: 'Студенческие организации',
    ),
    InstituteItem(
      icon: Icons.badge_outlined,
      label: 'Состав сотрудников',
      subtitle: 'Кафедры и отделы',
    ),
    InstituteItem(
      icon: Icons.share_outlined,
      label: 'Социальные сети',
      subtitle: 'Официальные страницы',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ИМИ СВФУ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          _WelcomeBanner(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'РАЗДЕЛЫ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  return Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(item.icon,
                              color: AppTheme.accentBlue, size: 20),
                        ),
                        title: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                          ),
                        ),
                        subtitle: Text(
                          item.subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppTheme.textMuted, size: 20),
                        onTap: () {},
                      ),
                      if (i < _items.length - 1)
                        const Divider(
                            height: 1, indent: 66, color: AppTheme.divider),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Добро пожаловать!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Институт математики и информатики',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.school, color: Colors.white54, size: 40),
          ],
        ),
      ),
    );
  }
}