import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;

      // ПРОВЕРКА: подтверждён ли email
      if (user != null && !user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          _showEmailNotVerifiedDialog(user);
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Произошла ошибка при входе';
      switch (e.code) {
        case 'user-not-found':
          message = 'Пользователь не найден';
          break;
        case 'wrong-password':
          message = 'Неверный пароль';
          break;
        case 'invalid-email':
          message = 'Некорректный email';
          break;
        case 'user-disabled':
          message = 'Аккаунт отключён';
          break;
        case 'too-many-requests':
          message = 'Слишком много попыток. Попробуйте позже';
          break;
        case 'invalid-credential':
          message = 'Неверный email или пароль';
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
          const SnackBar(
            content: Text('Произошла непредвиденная ошибка'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailNotVerifiedDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Email не подтверждён'),
          ],
        ),
        content: const Text(
          'Вы не подтвердили свой email. Проверьте почту и перейдите по ссылке из письма.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await user.sendEmailVerification();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Письмо отправлено повторно'),
                      backgroundColor: Colors.green,
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
                    ),
                  );
                }
              }
            },
            child: const Text('Отправить снова'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход для студентов'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.school,
                size: 80,
                color: AppTheme.primaryNavy,
              ),
              const SizedBox(height: 24),
              const Text(
                'Добро пожаловать!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Войдите в свою учетную запись ИМИ СВФУ',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 40),

              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 8),

              // ✅ ССЫЛКА "Забыли пароль?"
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const ForgotPasswordScreen(),
                    ),
                  ),
                  child: const Text(
                    'Забыли пароль?',
                    style: TextStyle(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
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
                  'Войти',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Нет аккаунта? ',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
                    child: const Text(
                      'Зарегистрироваться',
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}