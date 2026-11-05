import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../services/settings_service.dart';
import 'institute_screen.dart';
import 'admission_screen.dart';
import 'staff_screen.dart';
import 'profkom_screen.dart';
import 'indoor_map_screen.dart';

class GuestScreen extends StatelessWidget {
  const GuestScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance, // слушаем смену темы
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              tooltip: 'Назад',
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Гостевой режим'),
            actions: [
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
          backgroundColor: theme.scaffoldBackgroundColor,
          body: ListView(
            padding: const EdgeInsets.all(AppTheme.s16),
            children: [
              // Пояснение, что именно ограничено в гостевом режиме
              Container(
                padding: const EdgeInsets.all(AppTheme.s12),
                decoration: BoxDecoration(
                  color: appAccentSoftColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: appAccentColor(context), size: 22),
                    const SizedBox(width: AppTheme.s12),
                    Expanded(
                      child: Text(
                        'Расписание, зачётка и задания доступны после входа',
                        style: TextStyle(
                          fontSize: 13,
                          color: appAccentColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const AppSectionLabel('Доступно гостям'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    AppListRow(
                      icon: Icons.account_balance_outlined,
                      title: 'Об институте',
                      subtitle: 'История, направления, кафедры',
                      onTap: () => _open(context, const InstituteScreen()),
                    ),
                    const Divider(height: 1, indent: 64),
                    AppListRow(
                      icon: Icons.school_outlined,
                      title: 'Поступающим',
                      subtitle: 'Бакалавриат и магистратура',
                      onTap: () => _open(context, const AdmissionScreen()),
                    ),
                    const Divider(height: 1, indent: 64),
                    AppListRow(
                      icon: Icons.people_outline,
                      title: 'Сотрудники института',
                      subtitle: 'Руководство и преподаватели',
                      onTap: () => _open(context, const StaffScreen()),
                    ),
                    const Divider(height: 1, indent: 64),
                    AppListRow(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Профсоюз СВФУ',
                      subtitle: 'Студенческий профсоюз',
                      onTap: () => _open(context, const ProfkomScreen()),
                    ),
                    const Divider(height: 1, indent: 64),
                    AppListRow(
                      icon: Icons.map_outlined,
                      title: 'Карта корпуса',
                      subtitle: 'Навигация по этажам ИМИ',
                      onTap: () => _open(context, const IndoorMapScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.s16),
              // Приглашение войти
              AppCard(
                padding: const EdgeInsets.all(AppTheme.s16),
                child: Column(
                  children: [
                    Icon(Icons.lock_outline, size: 28, color: appAccentColor(context)),
                    const SizedBox(height: 6),
                    const Text(
                      'Больше возможностей после входа',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Расписание, оценки, задания и события',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: appMutedColor(context)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Войти'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.s24),
              Center(
                child: Text(
                  '© СВФУ им. М.К. Аммосова',
                  style: TextStyle(fontSize: 11, color: appMutedColor(context)),
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
