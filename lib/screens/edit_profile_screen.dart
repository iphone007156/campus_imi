import 'package:flutter/material.dart';
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

  bool _isLoading = false;
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

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 90,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      setState(() => _previewBytes = bytes);
      setState(() => _isLoading = true);

      final fileName = 'avatar_${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage.from('avatars').uploadBinary(
        fileName, Uint8List.fromList(bytes),
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
      setState(() => _newPhotoUrl = publicUrl);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // ✅ Сохраняем ТОЛЬКО ФИО и Телефон. Курс и группу менять нельзя!
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      if (_newPhotoUrl != null) {
        updates['photoUrl'] = _newPhotoUrl;
        updates['photoBase64'] = '';
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Профиль обновлен'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final oldPhotoBase64 = widget.userData['photoBase64'];
    final oldPhotoUrl = widget.userData['photoUrl'];
    final userGroup = widget.userData['group'] ?? 'Не указана';
    final userInstitute = widget.userData['institute'] ?? 'Не указано';
    final userCourse = widget.userData['course'] ?? 'Не указан';

    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        border: Border.all(color: Theme.of(context).cardColor, width: 4),
                        image: _previewBytes != null
                            ? DecorationImage(image: MemoryImage(_previewBytes!), fit: BoxFit.cover)
                            : (oldPhotoUrl != null && oldPhotoUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(oldPhotoUrl), fit: BoxFit.cover)
                            : (oldPhotoBase64 != null && oldPhotoBase64.isNotEmpty
                            ? DecorationImage(image: MemoryImage(base64Decode(oldPhotoBase64)), fit: BoxFit.cover)
                            : null)),
                      ),
                      child: (_previewBytes == null && (oldPhotoUrl == null || oldPhotoUrl.isEmpty) && (oldPhotoBase64 == null || oldPhotoBase64.isEmpty))
                          ? Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _pickAndUploadAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ✅ ЗАБЛОКИРОВАННЫЕ ПОЛЯ (только чтение)
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
                  helperText: 'Определяется автоматически по группе',
                ),
              ),
              const SizedBox(height: 24),

              // ✅ РЕДАКТИРУЕМЫЕ ПОЛЯ
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: 'ФИО', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Введите ФИО' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                enabled: !_isLoading,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Телефон', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Сохранить', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}