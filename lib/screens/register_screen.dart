import 'package:flutter/material.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedDeptId;
  String? _selectedGroup;
  int _calculatedCourse = 1; // ✅ Сюда сохраняем вычисленный курс

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const List<String> _allowedDomains = [
    's-vfu.ru', 'students.s-vfu.ru', 'yandex.ru', 'ya.ru', 'mail.ru', 'inbox.ru', 'list.ru', 'bk.ru', 'internet.ru', 'gmail.com', 'googlemail.com', 'icloud.com', 'me.com', 'mac.com',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ Функция автоматического вычисления курса по номеру группы
  int _calculateCourse(String groupName) {
    try {
      final match = RegExp(r'(\d{2})$').firstMatch(groupName);
      if (match == null) return 1;

      final yearSuffix = int.parse(match.group(1)!);
      final admissionYear = 2000 + yearSuffix;

      final now = DateTime.now();
      // Учебный год начинается с сентября
      final currentAcademicYear = now.month >= 9 ? now.year : now.year - 1;

      int course = currentAcademicYear - admissionYear + 1;

      // Ограничиваем от 1 до 5
      if (course < 1) return 1;
      if (course > 5) return 5;
      return course;
    } catch (e) {
      return 1;
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Введите email';
    if (!value.contains('@')) return 'Некорректный email';
    final domain = value.split('@').last.toLowerCase();
    if (!_allowedDomains.contains(domain)) return 'Этот домен не поддерживается';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeptId == null || _selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите подразделение и группу'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароли не совпадают'), backgroundColor: Colors.red),
      );
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

      final deptDoc = await FirebaseFirestore.instance.collection('departments').doc(_selectedDeptId).get();
      final deptName = deptDoc.data()?['name'] ?? '';

      // ✅ Сохраняем курс в формате "4 курс"
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'group': _selectedGroup,
        'departmentId': _selectedDeptId,
        'institute': deptName,
        'course': '$_calculatedCourse курс', // <-- Записываем вычисленный курс
        'phone': '',
        'role': 'student',
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'photoBase64': '',
      });

      await user.sendEmailVerification();

      if (mounted) _showVerificationDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
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
        title: const Text('Подтвердите email'),
        content: Text('Мы отправили письмо на ${_emailController.text.trim()}'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add_alt_1, size: 60, color: AppTheme.primaryNavy),
              const SizedBox(height: 16),
              Text('Создать аккаунт', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ФИО', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Введите ФИО' : null,
              ),
              const SizedBox(height: 16),

              // ✅ 1. Выбор подразделения
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('departments').orderBy('shortName').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final depts = snapshot.data!.docs.map((d) => Department.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();

                  final isValid = depts.any((d) => d.id == _selectedDeptId);

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Подразделение', border: OutlineInputBorder()),
                    value: isValid ? _selectedDeptId : null,
                    dropdownColor: Theme.of(context).cardColor,
                    items: depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.shortName))).toList(),
                    onChanged: _isLoading ? null : (val) {
                      setState(() {
                        _selectedDeptId = val;
                        _selectedGroup = null;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // ✅ 2. Выбор группы (фильтруется по ID подразделения)
              if (_selectedDeptId != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .where('departmentId', isEqualTo: _selectedDeptId)
                      .orderBy('name')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final groups = snapshot.data?.docs.map((d) => d['name'] as String).toList() ?? [];

                    final isValidGroup = groups.contains(_selectedGroup);

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Группа', border: OutlineInputBorder()),
                      value: isValidGroup ? _selectedGroup : null,
                      dropdownColor: Theme.of(context).cardColor,
                      items: groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: _isLoading ? null : (val) {
                        setState(() {
                          _selectedGroup = val;
                          // ✅ При выборе группы сразу вычисляем курс
                          if (val != null) {
                            _calculatedCourse = _calculateCourse(val);
                          }
                        });
                      },
                    );
                  },
                ),
              const SizedBox(height: 16),

              // ✅ 3. Поле Курс (только для чтения)
              if (_selectedGroup != null)
                TextFormField(
                  key: ValueKey(_calculatedCourse), // Обновляем поле при смене группы
                  initialValue: '$_calculatedCourse курс',
                  readOnly: true,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Курс (автоматически)',
                    prefixIcon: const Icon(Icons.layers_outlined),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.1),
                    helperText: 'Определяется автоматически по номеру группы',
                  ),
                ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
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

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
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

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Зарегистрироваться', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}