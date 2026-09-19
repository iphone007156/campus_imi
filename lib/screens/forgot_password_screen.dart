import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      String message = 'Ошибка отправки письма';
      switch (e.code) {
        case 'user-not-found':
          message = 'Пользователь с таким email не найден';
          break;
        case 'invalid-email':
          message = 'Некорректный email';
          break;
        case 'too-many-requests':
          message = 'Слишком много попыток. Попробуйте позже';
          break;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Восстановление пароля'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _emailSent ? _buildSuccessScreen() : _buildFormScreen(),
      ),
    );
  }

  Widget _buildFormScreen() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.lock_reset,
            size: 80,
            color: AppTheme.primaryNavy,
          ),
          const SizedBox(height: 24),
          const Text(
            'Забыли пароль?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Введите email, указанный при регистрации.\nМы отправим ссылку для сброса пароля.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Email
          TextFormField(
            controller: _emailController,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
              hintText: 'ivanov@students.s-vfu.ru',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введите email';
              }
              if (!value.contains('@')) {
                return 'Некорректный email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Кнопка
          ElevatedButton(
            onPressed: _isLoading ? null : _sendResetEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              'Отправить ссылку',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),

          // Подсказка
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppTheme.accentBlue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Проверьте папку «Спам», если письмо не пришло в течение 5 минут',
                    style: TextStyle(fontSize: 12, color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withValues(alpha: 0.1),
            border: Border.all(color: Colors.green, width: 3),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 50,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Письмо отправлено!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Мы отправили ссылку для сброса пароля на:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 8),
        Text(
          _emailController.text.trim(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Что делать дальше:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '1. Откройте почту\n'
                    '2. Найдите письмо от «СВФУ Кампус»\n'
                    '3. Перейдите по ссылке\n'
                    '4. Введите новый пароль\n'
                    '5. Вернитесь в приложение и войдите',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textDark,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppTheme.primaryNavy),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Вернуться к входу',
            style: TextStyle(
              color: AppTheme.primaryNavy,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}