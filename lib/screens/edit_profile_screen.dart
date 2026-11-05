import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Добавлено для inputFormatters
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isUploadingAvatar = false;

  String? _newPhotoUrl;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData['name'] ?? '';
    _phoneController.text = widget.userData['phone'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ✅ Валидация ФИО
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите ФИО';
    final name = value.trim();
    if (name.length < 2) return 'ФИО слишком короткое';
    if (name.length > 50) return 'ФИО слишком длинное (макс. 50)';
    // Разрешаем только русские/английские буквы, пробелы и дефисы
    if (!RegExp(r'^[а-яА-ЯёЁa-zA-Z\s\-]+$').hasMatch(name)) {
      return 'ФИО может содержать только буквы';
    }
    return null;
  }

  // ✅ Валидация Телефона
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите номер телефона';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 11) return 'Введите номер полностью';
    return null;
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _previewBytes = bytes;
        _isUploadingAvatar = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final fileName = 'avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage.from('avatars').uploadBinary(
        fileName,
        Uint8List.fromList(bytes),
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      ).timeout(const Duration(seconds: 30));

      final publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoUrl': publicUrl,
        'photoBase64': '',
      }).timeout(const Duration(seconds: 15));

      setState(() {
        _newPhotoUrl = publicUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Фото профиля обновлено!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка загрузки фото: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates)
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Профиль сохранен'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oldPhotoBase64 = widget.userData['photoBase64'];
    final oldPhotoUrl = widget.userData['photoUrl'];

    final userGroup = widget.userData['group'] ?? 'Не указана';
    final userInstitute = widget.userData['institute'] ?? 'Не указано';
    final userCourse = widget.userData['course'] ?? 'Не указан';

    ImageProvider? imageProvider;
    if (_previewBytes != null) {
      imageProvider = MemoryImage(_previewBytes!);
    } else if (_newPhotoUrl != null && _newPhotoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_newPhotoUrl!);
    } else if (oldPhotoUrl != null && oldPhotoUrl.isNotEmpty) {
      imageProvider = NetworkImage(oldPhotoUrl);
    } else if (oldPhotoBase64 != null && oldPhotoBase64.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(oldPhotoBase64));
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── АВАТАРКА ───────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        border: Border.all(color: theme.cardColor, width: 4),
                        image: imageProvider != null
                            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageProvider == null
                          ? Icon(Icons.person, size: 50, color: theme.colorScheme.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isUploadingAvatar ? Colors.grey : theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                          ),
                          child: _isUploadingAvatar
                              ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                              : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUploadingAvatar)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Загрузка фото...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              const SizedBox(height: 24),

              // ─── ЗАБЛОКИРОВАННЫЕ ПОЛЯ ─────────────────────────────
              TextFormField(
                initialValue: userInstitute,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Подразделение',
                  prefixIcon: Icon(Icons.school_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Для смены обратитесь в деканат',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: userGroup,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Группа',
                  prefixIcon: Icon(Icons.groups_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Для смены обратитесь в деканат',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: userCourse,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Курс',
                  prefixIcon: Icon(Icons.layers_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Определяется автоматически',
                ),
              ),
              const SizedBox(height: 24),

              // ─── РЕДАКТИРУЕМЫЕ ПОЛЯ ───────────────────────────────
              TextFormField(
                controller: _nameController,
                enabled: !_isSavingProfile,
                keyboardType: TextInputType.name,
                // ✅ Ограничиваем ввод: только буквы, пробелы и дефисы
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[а-яА-ЯёЁa-zA-Z\s\-]')),
                  LengthLimitingTextInputFormatter(50), // Максимум 50 символов
                ],
                decoration: const InputDecoration(
                  labelText: 'ФИО',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                enabled: !_isSavingProfile,
                keyboardType: TextInputType.phone,
                // ✅ Маска для телефона: +7 (XXX) XXX-XX-XX
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Только цифры
                  LengthLimitingTextInputFormatter(11),   // Максимум 11 цифр
                  _PhoneNumberFormatter(),                // Автоматическая маска
                ],
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  hintText: '+7 (999) 123-45-67',
                ),
                validator: _validatePhone,
              ),

              const SizedBox(height: 32),

              // ─── КНОПКА СОХРАНИТЬ ─────────────────────────────────
              ElevatedButton(
                onPressed: (_isSavingProfile || _isUploadingAvatar) ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSavingProfile
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Text('Сохранить', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Класс для красивой автоматической маски телефона
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