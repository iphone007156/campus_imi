import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/event_service.dart';
import '../utils/validators.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _endDateController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _locationController = TextEditingController();
  final _pointsController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final EventService _eventService = EventService();
  bool _isLoading = false;
  UserRole _currentRole = UserRole.student;

  // Режим загрузки: 'url' или 'file'
  String _imageMode = 'url';
  File? _selectedImage;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && mounted) {
      setState(() {
        _currentRole = UserModel.parseRole(doc.data()?['role']);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    _locationController.dispose();
    _pointsController.dispose();
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Фото выбрано'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
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
    }
  }

  DateTime? _parseDateTime(String dateStr, String timeStr) {
    try {
      final dateParts = dateStr.trim().split('.');
      final timeParts = timeStr.trim().split(':');
      if (dateParts.length == 3 && timeParts.length == 2) {
        return DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      }
    } catch (e) {
      debugPrint('Ошибка: $e');
    }
    return null;
  }

  Future<void> _addEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) throw Exception('Профиль не найден');

      final data = userDoc.data()!;
      final role = UserModel.parseRole(data['role']);
      final userName = data['name'] ?? 'Активист';

      if (!role.canCreateEvents) {
        throw Exception('Только активисты могут создавать мероприятия');
      }

      final points = int.parse(_pointsController.text.trim());

      if (role == UserRole.activist && points > 20) {
        throw Exception('Активист может ставить не более 20 баллов');
      }

      final endTime = _parseDateTime(
        _endDateController.text,
        _endTimeController.text,
      );

      if (endTime == null) {
        throw Exception('Некорректная дата окончания');
      }

      String imageUrl = '';
      String imageBase64 = '';

      if (_imageMode == 'url') {
        imageUrl = _imageUrlController.text.trim();
      } else {
        if (_imageBase64 != null) {
          imageBase64 = _imageBase64!;
        }
      }

      final event = Event(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _dateController.text.trim(),
        time: _timeController.text.trim(),
        location: _locationController.text.trim(),
        points: points,
        organizer: userName,
        organizerId: user.uid,
        imageUrl: imageUrl,
        imageBase64: imageBase64,
        participants: [],
        attended: [],
        endTime: endTime,
        finalized: false,
        createdAt: DateTime.now(),
      );

      await _eventService.addEvent(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Мероприятие создано!'),
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
    final maxPoints = _currentRole.maxPoints;

    return Scaffold(
      appBar: AppBar(title: const Text('Создать мероприятие')),
      backgroundColor: AppTheme.backgroundGray,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_currentRole == UserRole.activist)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.gold, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Вы активист. Максимум 20 баллов за мероприятие.',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                ),

              TextFormField(
                controller: _titleController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Название *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: Validators.validateEventTitle,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                enabled: !_isLoading,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Описание *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: Validators.validateEventDescription,
              ),
              const SizedBox(height: 16),

              const Text('Начало',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Дата *',
                      hintText: '20.09.2026',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateEventDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _timeController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Время *',
                      hintText: '14:00',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateEventTime,
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              const Text('Окончание',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _endDateController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Дата *',
                      hintText: '20.09.2026',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите дату';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _endTimeController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Время *',
                      hintText: '18:00',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите время';
                      }
                      return null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppTheme.accentBlue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'После окончания запись и отписка станут недоступны',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Место проведения *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: Validators.validateEventLocation,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _pointsController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Баллы за участие *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.star),
                  helperText: _currentRole == UserRole.activist
                      ? 'Максимум 20 баллов'
                      : 'Без ограничений',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите количество баллов';
                  }
                  final points = int.tryParse(value);
                  if (points == null) return 'Введите число';
                  if (points < 0) return 'Баллы не могут быть отрицательными';

                  if (_currentRole == UserRole.activist && points > 20) {
                    return 'Максимум 20 баллов для активиста';
                  }
                  if (maxPoints > 0 && points > maxPoints) {
                    return 'Максимум $maxPoints баллов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ===== ВЫБОР СПОСОБА ЗАГРУЗКИ ФОТО =====
              const Text('Изображение мероприятия',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted)),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ImageModeButton(
                        label: '🔗 URL',
                        selected: _imageMode == 'url',
                        onTap: () => setState(() => _imageMode = 'url'),
                      ),
                    ),
                    Expanded(
                      child: _ImageModeButton(
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

              if (_imageMode == 'url' &&
                  _imageUrlController.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _imageUrlController.text.trim(),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined,
                                  size: 40, color: AppTheme.textMuted),
                              SizedBox(height: 8),
                              Text('Не удалось загрузить изображение',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),
              Text(
                'Поля с * обязательны для заполнения',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addEvent,
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
                    'Создать мероприятие',
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

class _ImageModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ImageModeButton({
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