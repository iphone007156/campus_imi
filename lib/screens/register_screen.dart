import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Обязательно для фильтров ввода
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/department_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedDeptId;
  String? _selectedGroup;
  int _calculatedCourse = 1;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const List<String> _allowedDomains = [
    's-vfu.ru', 'students.s-vfu.ru', 'yandex.ru', 'ya.ru',
    'mail.ru', 'inbox.ru', 'list.ru', 'bk.ru', 'internet.ru',
    'gmail.com', 'googlemail.com', 'icloud.com', 'me.com',
    'mac.com',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ Автоматический расчёт курса
  int _calculateCourse(String groupName) {
    try {
      final match = RegExp(r'(\d{2})$').firstMatch(groupName);
      if (match == null) return 1;

      final yearSuffix = int.parse(match.group(1)!);
      final admissionYear = 2000 + yearSuffix;
      if (admissionYear < 2000 || admissionYear > 2100) return 1;

      final now = DateTime.now();
      final currentAcademicYear = now.month >= 9 ? now.year : now.year - 1;

      int course = currentAcademicYear - admissionYear + 1;
      if (course < 1) return 1;
      if (course > 5) return 5;
      return course;
    } catch (_) {
      return 1;
    }
  }

  // ✅ Валидация Email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Введите email';
    if (!value.contains('@')) return 'Некорректный email';
    final domain = value.split('@').last.toLowerCase();
    if (!_allowedDomains.contains(domain)) return 'Этот домен не поддерживается';
    return null;
  }

  // ✅ Валидация ФИО
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите ФИО';
    final name = value.trim();
    if (name.length < 2) return 'ФИО слишком короткое';
    return null;
  }

  // ✅ Валидация Телефона
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите номер телефона';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 11) return 'Введите номер полностью';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeptId == null || _selectedGroup == null) {
      _snack('Выберите подразделение и группу', error: true);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _snack('Пароли не совпадают', error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception('Не удалось создать пользователя');

      await user.updateDisplayName(_nameController.text.trim());

      final deptDoc = await FirebaseFirestore.instance
          .collection('departments')
          .doc(_selectedDeptId)
          .get();
      final deptName = deptDoc.data()?['name'] ?? '';

      // ✅ Сохраняем профиль в БД (включая телефон)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(), // Добавлен телефон
        'group': _selectedGroup,
        'departmentId': _selectedDeptId,
        'institute': deptName,
        'course': '$_calculatedCourse курс',
        'role': 'student',
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'photoBase64': '',
        'unionPoints': 0, // Инициализируем баллы
      });

      await user.sendEmailVerification();

      if (mounted) _showVerificationDialog();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Ошибка регистрации';
        switch (e.code) {
          case 'email-already-in-use':
            msg = 'Этот email уже зарегистрирован';
            break;
          case 'invalid-email':
            msg = 'Некорректный email';
            break;
          case 'weak-password':
            msg = 'Слишком слабый пароль';
            break;
          case 'operation-not-allowed':
            msg = 'Регистрация по email отключена';
            break;
        }
        _snack(msg, error: true);
      }
    } catch (e) {
      if (mounted) _snack('Ошибка: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите email'),
        content: Text('Мы отправили письмо на ${_emailController.text.trim()}'),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add_alt_1, size: 60, color: AppTheme.primaryNavy),
              const SizedBox(height: 16),
              Text('Создать аккаунт',
                  textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 24),

              // ─── ФИО ──────────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[а-яА-ЯёЁa-zA-Z\s\-]')),
                  LengthLimitingTextInputFormatter(50),
                ],
                decoration: const InputDecoration(
                  labelText: 'ФИО',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),

              // ─── ТЕЛЕФОН ──────────────────────────────────────────
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  _PhoneNumberFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  hintText: '+7 (999) 123-45-67',
                ),
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),

              // ─── ПОДРАЗДЕЛЕНИЕ ────────────────────────────────────
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('departments')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _errorBox('Не удалось загрузить подразделения');
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ));
                  }

                  final depts = snapshot.data!.docs
                      .map((d) => Department.fromMap(d.id, d.data() as Map<String, dynamic>))
                      .toList()
                    ..sort((a, b) => a.shortName.compareTo(b.shortName));

                  if (depts.isEmpty) {
                    return _errorBox('Подразделения ещё не добавлены администратором');
                  }

                  final isValid = depts.any((d) => d.id == _selectedDeptId);

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Подразделение',
                      border: OutlineInputBorder(),
                    ),
                    value: isValid ? _selectedDeptId : null,
                    dropdownColor: theme.cardColor,
                    items: depts
                        .map((d) => DropdownMenuItem(value: d.id, child: Text(d.shortName)))
                        .toList(),
                    onChanged: _isLoading
                        ? null
                        : (val) {
                      setState(() {
                        _selectedDeptId = val;
                        _selectedGroup = null;
                        _calculatedCourse = 1;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // ─── ГРУППА ───────────────────────────────────────────
              if (_selectedDeptId != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .where('departmentId', isEqualTo: _selectedDeptId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _errorBox('Ошибка загрузки групп. Проверьте соединение');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ));
                    }

                    final groups = (snapshot.data?.docs ?? [])
                        .map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['name'] as String?) ?? d.id;
                    })
                        .where((g) => g.isNotEmpty)
                        .toList()
                      ..sort();

                    if (groups.isEmpty) {
                      return _errorBox('В этом подразделении пока нет групп');
                    }

                    final isValidGroup = groups.contains(_selectedGroup);

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Группа',
                        border: OutlineInputBorder(),
                      ),
                      value: isValidGroup ? _selectedGroup : null,
                      dropdownColor: theme.cardColor,
                      items: groups
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: _isLoading
                          ? null
                          : (val) {
                        setState(() {
                          _selectedGroup = val;
                          if (val != null) {
                            _calculatedCourse = _calculateCourse(val);
                          }
                        });
                      },
                    );
                  },
                ),
              const SizedBox(height: 16),

              // ─── КУРС ─────────────────────────────────────────────
              if (_selectedGroup != null)
                TextFormField(
                  key: ValueKey('course_$_calculatedCourse'),
                  initialValue: '$_calculatedCourse курс',
                  readOnly: true,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Курс (автоматически)',
                    prefixIcon: const Icon(Icons.layers_outlined),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.1),
                    helperText: 'Определяется автоматически',
                  ),
                ),
              const SizedBox(height: 16),

              // ─── EMAIL ────────────────────────────────────────────
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(50),
                ],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),

              // ─── ПАРОЛЬ ───────────────────────────────────────────
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(30),
                ],
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Минимум 6 символов' : null,
              ),
              const SizedBox(height: 16),

              // ─── ПОВТОР ПАРОЛЯ ────────────────────────────────────
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(30),
                ],
                decoration: InputDecoration(
                  labelText: 'Повторите пароль',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) => (v != _passwordController.text) ? 'Пароли не совпадают' : null,
              ),
              const SizedBox(height: 24),

              // ─── КНОПКА РЕГИСТРАЦИИ ───────────────────────────────
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Зарегистрироваться', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
          ),
        ],
      ),
    );
  }
}

// ✅ Класс для автоматической маски телефона (+7 (999) 123-45-67)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final digits = text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    buffer.write('+7 ');
    if (digits.length > 1) {
      buffer.write('(');
      buffer.write(digits.substring(1, digits.length > 4 ? 4 : digits.length));
    }
    if (digits.length >= 4) {
      buffer.write(') ');
      buffer.write(digits.substring(4, digits.length > 7 ? 7 : digits.length));
    }
    if (digits.length >= 7) {
      buffer.write('-');
      buffer.write(digits.substring(7, digits.length > 9 ? 9 : digits.length));
    }
    if (digits.length >= 9) {
      buffer.write('-');
      buffer.write(digits.substring(9, digits.length > 11 ? 11 : digits.length));
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}