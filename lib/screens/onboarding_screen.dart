import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/settings_service.dart';
import 'privacy_policy_screen.dart';
import 'student_home_screen.dart'; // ✅ для fallback-навигации

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingScreen({super.key, this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  bool _notificationsGranted = false;
  bool _cameraGranted = false;
  bool _privacyChecked = false;
  bool _loading = true;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCurrentPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// ✅ При возврате из системных настроек перепроверяем разрешения
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_finishing) {
      _checkCurrentPermissions();
    }
  }

  Future<void> _checkCurrentPermissions() async {
    try {
      final notif = await Permission.notification.isGranted;
      final camera = await Permission.camera.isGranted;
      if (!mounted) return;
      setState(() {
        _notificationsGranted = notif;
        _cameraGranted = camera;
      });
    } on MissingPluginException catch (e) {
      debugPrint('⚠️ [ONBOARDING] permission_handler недоступен: $e');
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING] Ошибка проверки разрешений: $e');
    } finally {
      // ✅ ВСЕГДА сбрасываем флаг загрузки
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestNotifications() async {
    try {
      var status = await Permission.notification.status;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
      status = await Permission.notification.request();
      if (!mounted) return;
      setState(() => _notificationsGranted = status.isGranted);
      // NotificationService уже инициализирован в main() — повторно НЕ вызываем
    } on MissingPluginException catch (e) {
      debugPrint('⚠️ [ONBOARDING] permission_handler недоступен: $e');
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING] Ошибка запроса уведомлений: $e');
    }
  }

  Future<void> _requestCamera() async {
    try {
      var status = await Permission.camera.status;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
      status = await Permission.camera.request();
      if (!mounted) return;
      setState(() => _cameraGranted = status.isGranted);
    } on MissingPluginException catch (e) {
      debugPrint('⚠️ [ONBOARDING] permission_handler недоступен: $e');
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING] Ошибка запроса камеры: $e');
    }
  }

  /// ✅ Камера НЕ обязательна — её можно выдать позже при смене аватара
  bool get _canContinue => _notificationsGranted && _privacyChecked;

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    try {
      await SettingsService.instance.setPrivacyAccepted(true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING] Не удалось сохранить флаги: $e');
    }

    if (!mounted) return;

    if (widget.onCompleted != null) {
      widget.onCompleted!();
      return;
    }

    // ✅ Fallback: переходим на главный экран, а не на «вечный спиннер»
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Icon(Icons.school_outlined,
                    size: 80, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text('Привет! Давай всё настроим',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Чтобы приложение работало как надо, разреши доступ к '
                    'уведомлениям. Камеру можно выдать позже — она нужна '
                    'только для смены аватара.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              _PermissionCard(
                icon: Icons.notifications_outlined,
                title: 'Уведомления',
                subtitle: 'Напоминания о парах, новости, события',
                granted: _notificationsGranted,
                onRequest: _requestNotifications,
              ),
              const SizedBox(height: 12),
              _PermissionCard(
                icon: Icons.camera_alt_outlined,
                title: 'Камера (необязательно)',
                subtitle: 'Смена аватара профиля',
                granted: _cameraGranted,
                onRequest: _requestCamera,
              ),
              const SizedBox(height: 24),

              CheckboxListTile(
                value: _privacyChecked,
                onChanged: (v) async {
                  setState(() => _privacyChecked = v ?? false);
                  if (v == true) {
                    await SettingsService.instance.setPrivacyAccepted(true);
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Wrap(
                  children: [
                    const Text('Я согласен с '),
                    GestureDetector(
                      onTap: () async {
                        final accepted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const PrivacyPolicyScreen(showAcceptButton: true),
                          ),
                        );
                        if (accepted == true) {
                          setState(() => _privacyChecked = true);
                          await SettingsService.instance.setPrivacyAccepted(true);
                        }
                      },
                      child: Text(
                        'политикой конфиденциальности',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(' и обработкой персональных данных'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Кнопка «Продолжить» — активна при уведомлениях + политике
              ElevatedButton(
                onPressed: (_canContinue && !_finishing) ? _finish : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _finishing
                    ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Продолжить'),
              ),

              // ✅ Всегда доступная кнопка «Пропустить» — защита от залипания
              if (!_canContinue)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: _finishing ? null : _finish,
                    child: const Text('Пропустить (настрою позже)'),
                  ),
                ),

              if (!_notificationsGranted)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Для продолжения нужно разрешить уведомления и принять политику',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onRequest;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Icon(
                  icon,
                  size: 28,
                  color: granted ? Colors.green : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: granted ? null : onRequest,
            style: OutlinedButton.styleFrom(
              fixedSize: const Size.fromHeight(48),
              foregroundColor: granted ? Colors.green : null,
            ),
            child: Text(granted ? 'Разрешено' : 'Разрешить'),
          ),
        ],
      ),
    );
  }
}