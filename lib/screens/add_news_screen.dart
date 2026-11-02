import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../models/news_model.dart';
import '../models/department_model.dart'; // ✅
import '../services/news_service.dart';
import '../services/push_service.dart';

class AddNewsScreen extends StatefulWidget {
  final News? news;
  const AddNewsScreen({super.key, this.news});
  bool get isEditing => news != null;

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _bodyController = TextEditingController();
  final _sourceNameController = TextEditingController();
  final _sourceUrlController = TextEditingController();

  final NewsService _newsService = NewsService();
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;

  List<String> _imageUrls = [];
  String _category = 'События';
  String? _selectedDeptId; // ✅ Выбранное подразделение (null = общая новость)

  static const List<String> _categories = ['Trending', 'Спорт', 'Учёба', 'События', 'Культура'];

  @override
  void initState() {
    super.initState();
    if (widget.news != null) {
      final news = widget.news!;
      _titleController.text = news.title;
      _shortDescController.text = news.shortDescription;
      _bodyController.text = news.body;
      _category = news.category;
      _sourceNameController.text = news.sourceName;
      _sourceUrlController.text = news.sourceUrl;
      _imageUrls = List.from(news.imageUrls);
      _selectedDeptId = news.departmentId.isNotEmpty ? news.departmentId : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _bodyController.dispose();
    _sourceNameController.dispose();
    _sourceUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
      if (images.isEmpty) return;

      setState(() => _isLoading = true);

      for (var image in images) {
        final bytes = await image.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        await _supabase.storage.from('news_images').uploadBinary(
          fileName, Uint8List.fromList(bytes),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
        final publicUrl = _supabase.storage.from('news_images').getPublicUrl(fileName);
        setState(() => _imageUrls.add(publicUrl));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки фото: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? (widget.news?.authorName ?? 'Администратор');

      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

      final news = News(
        id: widget.news?.id ?? '',
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        shortDescription: _shortDescController.text.trim(),
        date: widget.news?.date ?? dateStr,
        category: _category,
        authorName: userName,
        authorId: widget.news?.authorId ?? user.uid,
        departmentId: _selectedDeptId ?? '', // ✅ Пусто = общая
        imageUrls: _imageUrls,
        imageBase64: '',
        createdAt: widget.news?.createdAt ?? DateTime.now(),
        sourceName: _sourceNameController.text.trim(),
        sourceUrl: _sourceUrlController.text.trim(),
      );

      if (widget.isEditing) {
        await _newsService.updateNews(news);
      } else {
        await _newsService.addNews(news);

        // Отправляем пуш всем (в будущем можно фильтровать по departmentId)
        await PushService.sendToAll(
          title: 'Новость: ${news.title}',
          message: news.shortDescription.isNotEmpty ? news.shortDescription : 'Нажмите, чтобы прочитать',
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNews() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить новость?'),
        content: Text('Новость "${widget.news?.title}" будет удалена навсегда.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _newsService.deleteNews(widget.news!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Редактировать новость' : 'Добавить новость'),
        actions: [
          if (widget.isEditing)
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white), onPressed: _isLoading ? null : _deleteNews),
        ],
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: 'Заголовок *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Введите заголовок' : null,
              ),
              const SizedBox(height: 16),

              // ✅ ВЫБОР ПОДРАЗДЕЛЕНИЯ
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('departments').orderBy('shortName').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();

                  final depts = snapshot.data!.docs.map((d) => Department.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Подразделение (если пусто - для всех)', border: OutlineInputBorder()),
                    value: _selectedDeptId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все (общая новость)')),
                      ...depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.shortName))),
                    ],
                    onChanged: _isLoading ? null : (v) => setState(() => _selectedDeptId = v),
                  );
                },
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: AppTheme.divider), borderRadius: BorderRadius.circular(4)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _category,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: _isLoading ? null : (v) => setState(() => _category = v!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _shortDescController,
                enabled: !_isLoading,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Краткое описание *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Введите описание' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bodyController,
                enabled: !_isLoading,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Полный текст *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Введите текст' : null,
              ),
              const SizedBox(height: 20),

              const Text('Фотографии', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _isLoading ? null : _pickAndUploadImages,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 30, color: AppTheme.textMuted),
                      SizedBox(height: 4),
                      Text('Нажмите, чтобы добавить фото', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ),

              if (_imageUrls.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                    itemCount: _imageUrls.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(_imageUrls[index], width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _imageUrls.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),
              const Text('Источник (необязательно)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _sourceNameController,
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: 'Название источника', hintText: 'Например: КМС ППОС СВФУ «Точка Кипения»', border: OutlineInputBorder(), prefixIcon: Icon(Icons.info_outline)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sourceUrlController,
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: 'Ссылка на источник (URL)', hintText: 'https://vk.com/wall...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link)),
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveNews,
                  icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(widget.isEditing ? Icons.save : Icons.publish),
                  label: Text(_isLoading ? 'Сохранение...' : (widget.isEditing ? 'Сохранить' : 'Опубликовать')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}