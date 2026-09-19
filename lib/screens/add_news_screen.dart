import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';

class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({super.key});

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final NewsService _newsService = NewsService();
  bool _isLoading = false;

  String _imageMode = 'url';
  File? _selectedImage;
  String? _imageBase64;

  String _category = 'События';
  static const List<String> _categories = [
    'Trending',
    'Спорт',
    'Учёба',
    'События',
    'Культура',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (bytes.length > 700000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Фото слишком большое (макс. ~700 КБ)'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedImage = File(image.path);
        _imageBase64 = base64Encode(bytes);
      });
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
    }
  }

  Future<void> _addNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Получаем имя автора
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Администратор';

      // Формируем дату
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

      String imageUrl = '';
      String imageBase64 = '';

      if (_imageMode == 'url') {
        imageUrl = _imageUrlController.text.trim();
      } else {
        if (_imageBase64 != null) {
          imageBase64 = _imageBase64!;
        }
      }

      final news = News(
        id: '',
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        shortDescription: _shortDescController.text.trim(),
        date: dateStr,
        category: _category,
        authorName: userName,
        authorId: user.uid,
        imageUrl: imageUrl,
        imageBase64: imageBase64,
        createdAt: DateTime.now(),
      );

      await _newsService.addNews(news);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Новость опубликована!'),
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
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить новость')),
      backgroundColor: AppTheme.backgroundGray,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок
              TextFormField(
                controller: _titleController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Заголовок *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите заголовок';
                  if (v.length < 5) return 'Минимум 5 символов';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Категория
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _category,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          const Icon(Icons.category,
                              size: 20,
                              color: AppTheme.textMuted),
                          const SizedBox(width: 8),
                          Text(c),
                        ],
                      ),
                    ))
                        .toList(),
                    onChanged: _isLoading
                        ? null
                        : (v) {
                      if (v != null) {
                        setState(() => _category = v);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Краткое описание
              TextFormField(
                controller: _shortDescController,
                enabled: !_isLoading,
                maxLines: 2,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Краткое описание * (для превью)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.short_text),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите описание';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Полный текст
              TextFormField(
                controller: _bodyController,
                enabled: !_isLoading,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Полный текст *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.article),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите текст';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ===== ИЗОБРАЖЕНИЕ =====
              const Text(
                'Изображение',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              // Переключатель URL / Галерея
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: '🔗 URL',
                        selected: _imageMode == 'url',
                        onTap: () => setState(() => _imageMode = 'url'),
                      ),
                    ),
                    Expanded(
                      child: _ModeButton(
                        label: '📷 Галерея',
                        selected: _imageMode == 'file',
                        onTap: () => setState(() => _imageMode = 'file'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_imageMode == 'url')
                TextFormField(
                  controller: _imageUrlController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'URL изображения',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                    hintText: 'https://example.com/image.jpg',
                  ),
                  onChanged: (_) => setState(() {}),
                ),

              if (_imageMode == 'file') ...[
                GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedImage != null
                            ? Colors.green
                            : AppTheme.divider,
                        width: _selectedImage != null ? 2 : 1,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        children: [
                          Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('Выбрано',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 50, color: AppTheme.textMuted),
                        SizedBox(height: 8),
                        Text('Нажмите для выбора фото',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted)),
                        SizedBox(height: 4),
                        Text('Максимум ~700 КБ',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _imageBase64 = null;
                      });
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    label: const Text('Удалить фото',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ],

              // Превью URL
              if (_imageMode == 'url' &&
                  _imageUrlController.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _imageUrlController.text.trim(),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        color: AppTheme.cardWhite,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined,
                              size: 40, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),
              Text(
                'Поля с * обязательны',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),

              // Кнопка публикации
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addNews,
                  icon: _isLoading
                      ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.publish),
                  label: Text(_isLoading ? 'Публикация...' : 'Опубликовать'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textDark,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}