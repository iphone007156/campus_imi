import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/department_model.dart';
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

  String? _selectedDeptId;
  String? _userDeptId;

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

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (doc.exists && mounted) {
      setState(() {
        _currentRole = UserModel.parseRole(doc.data()?['role']);
        _userDeptId = doc.data()?['departmentId'];
        _selectedDeptId = _userDeptId;
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
      final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 70);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 700000) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Фото слишком большое (макс. ~700 КБ)'), backgroundColor: Colors.red));
        return;
      }
      setState(() {
        _selectedImage = File(image.path);
        _imageBase64 = base64Encode(bytes);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    }
  }

  DateTime? _parseDateTime(String dateStr, String timeStr) {
    try {
      final dateParts = dateStr.trim().split('.');
      final timeParts = timeStr.trim().split(':');
      if (dateParts.length == 3 && timeParts.length == 2) {
        return DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]), int.parse(timeParts[0]), int.parse(timeParts[1]));
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

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('Профиль не найден');

      final data = userDoc.data()!;
      final role = UserModel.parseRole(data['role']);
      final userName = data['name'] ?? 'Активист';

      if (!role.canCreateEvents) throw Exception('Только активисты могут создавать мероприятия');

      final points = int.parse(_pointsController.text.trim());
      if (role == UserRole.activist && points > 20) throw Exception('Активист может ставить не более 20 баллов');

      final endTime = _parseDateTime(_endDateController.text, _endTimeController.text);
      if (endTime == null) throw Exception('Некорректная дата окончания');

      String imageUrl = '';
      String imageBase64 = '';
      if (_imageMode == 'url') {
        imageUrl = _imageUrlController.text.trim();
      } else {
        if (_imageBase64 != null) imageBase64 = _imageBase64!;
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
        departmentId: _selectedDeptId ?? '',
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Мероприятие создано!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxPoints = _currentRole.maxPoints;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Создать мероприятие')),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅
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
                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.gold, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Вы активист. Максимум 20 баллов за мероприятие.', style: TextStyle(fontSize: 12, color: AppTheme.textDark))),
                    ],
                  ),
                ),

              // ✅ ВЫБОР ПОДРАЗДЕЛЕНИЯ
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('departments').orderBy('shortName').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final depts = snapshot.data!.docs.map((d) => Department.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Подразделение (если пусто - для всех)', border: OutlineInputBorder()),
                    value: _selectedDeptId,
                    dropdownColor: Theme.of(context).cardColor, // ✅
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все (общее мероприятие)')),
                      ...depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.shortName))),
                    ],
                    onChanged: _isLoading ? null : (v) => setState(() => _selectedDeptId = v),
                  );
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Название *', prefixIcon: Icon(Icons.title), border: OutlineInputBorder()),
                validator: Validators.validateEventTitle,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Описание *', prefixIcon: Icon(Icons.description), border: OutlineInputBorder()),
                validator: Validators.validateEventDescription,
              ),
              const SizedBox(height: 16),

              const Text('Начало', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(controller: _dateController, decoration: const InputDecoration(labelText: 'Дата *', hintText: '20.09.2026', border: OutlineInputBorder()), validator: Validators.validateEventDate)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _timeController, decoration: const InputDecoration(labelText: 'Время *', hintText: '14:00', border: OutlineInputBorder()), validator: Validators.validateEventTime)),
              ]),
              const SizedBox(height: 16),

              const Text('Окончание', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(controller: _endDateController, decoration: const InputDecoration(labelText: 'Дата *', hintText: '20.09.2026', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Введите дату' : null)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _endTimeController, decoration: const InputDecoration(labelText: 'Время *', hintText: '18:00', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Введите время' : null)),
              ]),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Место проведения *', prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder()),
                validator: Validators.validateEventLocation,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Баллы за участие *',
                  prefixIcon: const Icon(Icons.star),
                  border: const OutlineInputBorder(),
                  helperText: _currentRole == UserRole.activist ? 'Максимум 20 баллов' : 'Без ограничений',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите количество баллов';
                  final points = int.tryParse(value);
                  if (points == null) return 'Введите число';
                  if (points < 0) return 'Баллы не могут быть отрицательными';
                  if (_currentRole == UserRole.activist && points > 20) return 'Максимум 20 баллов для активиста';
                  if (maxPoints > 0 && points > maxPoints) return 'Максимум $maxPoints баллов';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text('Изображение мероприятия', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor, // ✅
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).dividerColor)
                ),
                child: Row(
                  children: [
                    Expanded(child: _ImageModeButton(label: '🔗 URL', selected: _imageMode == 'url', onTap: () => setState(() => _imageMode = 'url'))),
                    Expanded(child: _ImageModeButton(label: '📷 Галерея', selected: _imageMode == 'file', onTap: () => setState(() => _imageMode = 'file'))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_imageMode == 'url')
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'URL изображения', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link), hintText: 'https://example.com/image.jpg'),
                  onChanged: (_) => setState(() {}),
                ),
              if (_imageMode == 'file') ...[
                GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor, // ✅
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _selectedImage != null ? Colors.green : Theme.of(context).dividerColor, width: _selectedImage != null ? 2 : 1),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.file(_selectedImage!, width: double.infinity, height: 180, fit: BoxFit.cover))
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 50, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(height: 8),
                        Text('Нажмите для выбора фото', style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addEvent,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary, // ✅
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Создать мероприятие', style: TextStyle(fontSize: 16)),
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

  const _ImageModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent, // ✅
            borderRadius: BorderRadius.circular(9)
        ),
        child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14
            )
        ),
      ),
    );
  }
}