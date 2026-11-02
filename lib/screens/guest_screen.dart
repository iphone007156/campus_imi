import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart'; // ✅ Импорт для смены темы
import 'institute_screen.dart';
import 'admission_screen.dart';
import 'staff_screen.dart';
import 'profkom_screen.dart';
import 'indoor_map_screen.dart';

class GuestScreen extends StatelessWidget {
  const GuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: SettingsService.instance, // ✅ Слушаем смену темы
      builder: (context, _) {
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Гостевой режим'),
            actions: [
              // ✅ Кнопка переключения темы
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: isDark ? Colors.amber : Colors.white,
                ),
                tooltip: 'Сменить тему',
                onPressed: () {
                  SettingsService.instance.setTheme(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
              ),
            ],
          ),
          backgroundColor: theme.scaffoldBackgroundColor, // ✅ Динамический фон
          body: ListView(
            padding: const EdgeInsets.all(AppTheme.s16),
            children: [
              const SizedBox(height: AppTheme.s8),
              Container(
                padding: const EdgeInsets.all(AppTheme.s16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppTheme.s12),
                    Expanded(
                      child: Text(
                        'Вы в режиме гостя. Часть разделов доступна только авторизованным студентам.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.s24),
              Text('ДОСТУПНО ГОСТЯМ', style: theme.textTheme.labelSmall),
              const SizedBox(height: AppTheme.s8),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor, // ✅ Динамический цвет карточки
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.shadowSoft,
                ),
                child: Column(
                  children: [
                    _GuestTile(
                      icon: Icons.account_balance,
                      label: 'Об институте',
                      subtitle: 'История, направления, кафедры',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstituteScreen())),
                    ),
                    Divider(indent: 72, endIndent: 16, color: theme.dividerColor),
                    _GuestTile(
                      icon: Icons.school_outlined,
                      label: 'Поступающим',
                      subtitle: 'Бакалавриат и магистратура',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdmissionScreen())),
                    ),
                    Divider(indent: 72, endIndent: 16, color: theme.dividerColor),
                    _GuestTile(
                      icon: Icons.people_outline,
                      label: 'Сотрудники института',
                      subtitle: 'Руководство и преподаватели',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffScreen())),
                    ),
                    Divider(indent: 72, endIndent: 16, color: theme.dividerColor),
                    _GuestTile(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Профсоюз СВФУ',
                      subtitle: 'Студенческий профсоюз',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfkomScreen())),
                    ),
                    Divider(indent: 72, endIndent: 16, color: theme.dividerColor),
                    _GuestTile(
                      icon: Icons.map_outlined,
                      label: 'Карта корпуса',
                      subtitle: 'Навигация по этажам ИМИ',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IndoorMapScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.s24),
              Center(
                child: Text(
                  '© СВФУ им. М.К. Амосова',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.disabledColor,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.s16),
            ],
          ),
        );
      },
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
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.s16, vertical: AppTheme.s12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: AppTheme.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.disabledColor, size: 20),
          ],
        ),
      ),
    );
  }
}