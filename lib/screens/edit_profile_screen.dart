import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _groupController = TextEditingController();
  final _instituteController = TextEditingController();
  final _courseController = TextEditingController();
  final _directionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;
  String? _currentPhotoBase64;
  bool _hasNewImage = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData['name'] ?? '';
    _groupController.text = widget.userData['group'] ?? '';
    _instituteController.text = widget.userData['institute'] ?? '';
    _courseController.text = widget.userData['course'] ?? '';
    _directionController.text = widget.userData['direction'] ?? '';
    _phoneController.text = widget.userData['phone'] ?? '';
    _emailController.text = widget.userData['email'] ?? '';
    _currentPhotoBase64 = widget.userData['photoBase64'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    _instituteController.dispose();
    _courseController.dispose();
    _directionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 50,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _hasNewImage = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Фото выбрано, нажмите Сохранить'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Ошибка выбора изображения: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _imageToBase64(File image) {
    try {
      if (!image.existsSync()) {
        print('❌ Файл не существует!');
        return null;
      }

      final bytes = image.readAsBytesSync();
      print('📸 Размер фото: ${bytes.length} байт');

      if (bytes.isEmpty) {
        print('❌ Файл пустой!');
        return null;
      }

      final base64String = base64Encode(bytes);
      print('✅ Base64 длина: ${base64String.length} символов');
      return base64String;
    } catch (e) {
      print('❌ Ошибка конвертации: $e');
      return null;
    }
  }

  ImageProvider? _getImageFromBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      print('❌ Ошибка декодирования: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }

      final updateData = {
        'name': _nameController.text.trim(),
        'group': _groupController.text.trim(),
        'institute': _instituteController.text.trim(),
        'course': _courseController.text.trim(),
        'direction': _directionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_hasNewImage && _selectedImage != null) {
        print('🔄 Конвертация фото...');
        final base64String = _imageToBase64(_selectedImage!);

        if (base64String != null && base64String.isNotEmpty) {
          if (base64String.length > 1000000) {
            throw Exception('Фото слишком большое! Используйте меньшее фото.');
          }
          updateData['photoBase64'] = base64String;
          print('✅ Фото добавлено в данные');
        } else {
          throw Exception('Не удалось конвертировать фото');
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      await user.updateDisplayName(_nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Профиль успешно обновлён!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        print('❌ Ошибка: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_currentPhotoBase64 != null && _currentPhotoBase64!.isNotEmpty) {
      imageProvider = _getImageFromBase64(_currentPhotoBase64);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
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
              'Сохранить',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.lightBlue,
                        border: Border.all(
                          color: AppTheme.accentBlue,
                          width: 3,
                        ),
                        image: imageProvider != null
                            ? DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: imageProvider == null
                          ? const Icon(
                        Icons.person,
                        size: 56,
                        color: AppTheme.accentBlue,
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryNavy,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _pickImage,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _hasNewImage
                    ? '✅ Фото выбрано, нажмите Сохранить'
                    : (_currentPhotoBase64 != null && _currentPhotoBase64!.isNotEmpty
                    ? '✅ Фото загружено'
                    : 'Нажмите на камеру для выбора фото'),
                style: TextStyle(
                  fontSize: 12,
                  color: _hasNewImage || (_currentPhotoBase64 != null && _currentPhotoBase64!.isNotEmpty)
                      ? Colors.green
                      : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // ФИО
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'ФИО',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: Validators.validateName,
              ),
              const SizedBox(height: 16),

              // ГРУППА
              TextFormField(
                controller: _groupController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Группа',
                  prefixIcon: Icon(Icons.groups_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'Например: Б-ПИГМУ-24',
                ),
                validator: Validators.validateGroup,
              ),
              const SizedBox(height: 16),

              // Институт
              TextFormField(
                controller: _instituteController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Институт',
                  prefixIcon: Icon(Icons.school_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Курс
              TextFormField(
                controller: _courseController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Курс',
                  prefixIcon: Icon(Icons.layers_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Направление
              TextFormField(
                controller: _directionController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Направление',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email (нельзя изменить)',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(height: 16),

              // Телефон
              TextFormField(
                controller: _phoneController,
                enabled: !_isLoading,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Сохранить изменения',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}