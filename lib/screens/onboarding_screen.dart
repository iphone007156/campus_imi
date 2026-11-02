import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/settings_service.dart';
import 'privacy_policy_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingScreen({super.key, this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _notificationsGranted = false;
  bool _cameraGranted = false;
  bool _privacyChecked = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    try {
      final notif = await Permission.notification.isGranted;
      final camera = await Permission.camera.isGranted;
      if (!mounted) return;
      setState(() {
        _notificationsGranted = notif;
        _cameraGranted = camera;
        _loading = false;
      });
    } on MissingPluginException catch (e) {
      debugPrint('⚠️ [ONBOARDING] permission_handler недоступен: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING] Ошибка проверки разрешений: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _requestNotifications() async {
    try {
      final status = await Permission.notification.request();
      if (!mounted) return;
      setState(() => _notificationsGranted = status.isGranted);
      if (status.isGranted) {
        await NotificationService.initialize();
      }
    } on MissingPluginException catch (e) {
      debugPrint('⚠️ [ONBOARDING] permission_handler недоступен: $e');
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING] Ошибка запроса уведомлений: $e');
    }
  }

  Future<void> _requestCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!mounted) return;
      setState(() => _cameraGranted = status.isGranted);
    } on MissingPluginException catch (e) {
      debugPrint('⚠️ [ONBOARDING] permission_handler недоступен: $e');
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING] Ошибка запроса камеры: $e');
    }
  }

  bool get _allGranted =>
      _notificationsGranted && _cameraGranted && _privacyChecked;

  Future<void> _finish() async {
    await SettingsService.instance.setPrivacyAccepted(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    if (widget.onCompleted != null) {
      widget.onCompleted!();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: CircularProgressIndicator()))),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                child: Icon(
                  Icons.school_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Привет! Давай всё настроим',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Чтобы приложение работало как надо, разреши доступ к следующим функциям.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
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
                title: 'Камера',
                subtitle: 'Смена аватара профиля',
                granted: _cameraGranted,
                onRequest: _requestCamera,
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _privacyChecked,
                onChanged: (v) => setState(() => _privacyChecked = v ?? false),
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
                            builder: (_) => const PrivacyPolicyScreen(showAcceptButton: true),
                          ),
                        );
                        if (accepted == true) {
                          setState(() => _privacyChecked = true);
                        }
                      },
                      child: Text(
                        'политикой конфиденциальности',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(' и обработкой персональных данных'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _allGranted ? _finish : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Продолжить'),
              ),
              if (!_allGranted)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Выдайте все разрешения и примите политику, чтобы продолжить',
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