import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'institute_screen.dart';
import 'news_screen.dart';
import 'profkom_screen.dart';

class GuestScreen extends StatelessWidget {
  const GuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Гостевой режим'),
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          _GuestBanner(),
          const SizedBox(height: 20),
          Text(
            'ДОСТУПНО ГОСТЯМ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                // ===== ИМИ СВФУ =====
                _GuestTile(
                  icon: Icons.account_balance_outlined,
                  label: 'ИМИ СВФУ',
                  subtitle: 'Информация об институте',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InstituteScreen()),
                  ),
                ),
                const Divider(
                    height: 1, indent: 66, color: AppTheme.divider),

                // ===== НОВОСТИ =====
                _GuestTile(
                  icon: Icons.newspaper_outlined,
                  label: 'Новости',
                  subtitle: 'Открытые новости института',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewsScreen()),
                  ),
                ),
                const Divider(
                    height: 1, indent: 66, color: AppTheme.divider),

                // ===== ПРОФСОЮЗ СВФУ =====
                _GuestTile(
                  icon: Icons.people_outline,
                  label: 'Профсоюз СВФУ',
                  subtitle: 'ППОС СВФУ — 10 000+ студентов',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfkomScreen()),
                  ),
                ),
                const Divider(
                    height: 1, indent: 66, color: AppTheme.divider),

                // ===== КАРТА КАМПУСА =====
                _GuestTile(
                  icon: Icons.map_outlined,
                  label: 'Карта кампуса',
                  subtitle: 'Схема корпусов',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Раздел в разработке'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© СВФУ им. М.К. Амосова',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightBlue),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: AppTheme.accentBlue, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Вы в режиме гостя. Часть разделов доступна только авторизованным студентам.',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textDark, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _GuestTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardWhite,
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppTheme.accentBlue, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        trailing: const Icon(Icons.chevron_right,
            color: AppTheme.textMuted, size: 20),
        onTap: onTap,
      ),
    );
  }
}