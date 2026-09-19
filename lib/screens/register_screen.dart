import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _groupController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ✅ РАЗРЕШЁННЫЕ ДОМЕНЫ (включая iCloud)
  static const List<String> _allowedDomains = [
    // Университетские
    's-vfu.ru',
    'students.s-vfu.ru',

    // Российские
    'yandex.ru',
    'ya.ru',
    'mail.ru',
    'inbox.ru',
    'list.ru',
    'bk.ru',
    'internet.ru',

    // Google
    'gmail.com',
    'googlemail.com',

    // ✅ Apple iCloud
    'icloud.com',
    'me.com',
    'mac.com',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Введите email';
    if (!value.contains('@')) return 'Некорректный email';

    final domain = value.split('@').last.toLowerCase();
    if (!_allowedDomains.contains(domain)) {
      return 'Этот домен не поддерживается';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    if (value.length < 6) return 'Минимум 6 символов';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Введите ФИО';
    if (value.length < 3) return 'Слишком короткое ФИО';
    return null;
  }

  String? _validateGroup(String? value) {
    if (value == null || value.isEmpty) return 'Введите группу';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пароли не совпадают'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception('Не удалось создать пользователя');

      await user.updateDisplayName(_nameController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'group': _groupController.text.trim(),
        'institute': 'ИМИ СВФУ',
        'course': '1 курс',
        'direction': 'Прикладная математика',
        'phone': '',
        'role': 'student',
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'photoBase64': '',
      });

      await user.sendEmailVerification();

      if (mounted) {
        _showVerificationDialog();
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Ошибка регистрации';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Этот email уже зарегистрирован';
          break;
        case 'invalid-email':
          message = 'Некорректный email';
          break;
        case 'weak-password':
          message = 'Слишком простой пароль';
          break;
        case 'operation-not-allowed':
          message = 'Регистрация временно отключена';
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

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email_outlined, color: AppTheme.accentBlue),
            SizedBox(width: 8),
            Text('Подтвердите email'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Мы отправили письмо на адрес:',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              _emailController.text.trim(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Перейдите по ссылке в письме, чтобы подтвердить аккаунт.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Icon(
                Icons.person_add_alt_1,
                size: 60,
                color: AppTheme.primaryNavy,
              ),
              const SizedBox(height: 16),
              const Text(
                'Создать аккаунт',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Регистрация доступна только студентам ИМИ СВФУ',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'ФИО',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _groupController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Группа',
                  prefixIcon: Icon(Icons.groups_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'Например: Б-ПИГМУ-24',
                ),
                validator: _validateGroup,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'Поддерживается: Gmail, Yandex, Mail, iCloud',
                  helperText: 'Поддерживается: Gmail, Yandex, Mail, iCloud',
                ),
                validator: _validateEmail,
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
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                enabled: !_isLoading,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Повторите пароль',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Повторите пароль';
                  }
                  if (value != _passwordController.text) {
                    return 'Пароли не совпадают';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
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
                  'Зарегистрироваться',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  'Уже есть аккаунт? Войти',
                  style: TextStyle(color: AppTheme.accentBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}