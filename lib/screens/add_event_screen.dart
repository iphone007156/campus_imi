import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/event_model.dart';
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
  final _locationController = TextEditingController();
  final _pointsController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final EventService _eventService = EventService();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _pointsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _addEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Получаем имя пользователя из Firestore
      String userName = user.displayName ?? 'Активист';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          userName = data['name'] ?? user.displayName ?? 'Активист';
        }
      } catch (e) {
        print('Ошибка получения имени: $e');
      }

      final event = Event(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _dateController.text.trim(),
        time: _timeController.text.trim(),
        location: _locationController.text.trim(),
        points: int.parse(_pointsController.text.trim()),
        organizer: userName,
        organizerId: user.uid,
        imageUrl: _imageUrlController.text.trim(),
        participants: [],
        createdAt: DateTime.now(),
      );

      await _eventService.addEvent(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Мероприятие успешно создано!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        print('❌ Ошибка создания мероприятия: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать мероприятие'),
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Название
              TextFormField(
                controller: _titleController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Название мероприятия *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: Validators.validateEventTitle,
              ),
              const SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                enabled: !_isLoading,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Описание *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                validator: Validators.validateEventDescription,
              ),
              const SizedBox(height: 16),

              // Дата и время
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Дата * (ДД.ММ.ГГГГ)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
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
                        labelText: 'Время * (ЧЧ:ММ)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      validator: Validators.validateEventTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Место
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

              // Баллы
              TextFormField(
                controller: _pointsController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Баллы за участие *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                ),
                validator: Validators.validateEventPoints,
              ),
              const SizedBox(height: 16),

              // URL изображения
              TextFormField(
                controller: _imageUrlController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'URL изображения (опционально)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                  hintText: 'https://example.com/image.jpg',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Поля с * обязательны для заполнения',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // Кнопка создания
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