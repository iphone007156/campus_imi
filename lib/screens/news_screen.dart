import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/news_model.dart';
import 'news_detail_screen.dart';
import 'add_news_screen.dart';
import '../services/news_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Все';
  String? _userDeptId;

  // ✅ По умолчанию показываем ТОЛЬКО новости своего подразделения
  bool _showOnlyMyDept = true;
  bool _isAdmin = false;

  final List<String> _categories = ['Все', 'Trending', 'Спорт', 'Учёба', 'События', 'Культура'];

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        if (mounted) {
          setState(() {
            _isAdmin = doc.data()?['role'] == 'admin';
            _userDeptId = doc.data()?['departmentId'];
            // Если у пользователя нет departmentId (старый аккаунт),
            // принудительно показываем "Все новости", чтобы он не видел пустой экран
            if (_userDeptId == null) _showOnlyMyDept = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showOptionsDialog(News news) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.accentBlue),
              title: const Text('Редактировать'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddNewsScreen(news: news)));
                if (result == true && mounted) setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Удалить новость?'),
                    content: const Text('Это действие нельзя отменить.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Удалить'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _newsService.deleteNews(news.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Новость удалена'), backgroundColor: Colors.green));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
        title: const Text('Новости'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNewsScreen()));
                if (mounted) setState(() {});
              },
            ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ Динамический фон
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor, // ✅ Динамический цвет панели
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск новостей...',
                    prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodySmall?.color),
                    fillColor: Theme.of(context).scaffoldBackgroundColor, // ✅ Динамический цвет поля
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
                const SizedBox(height: 12),

                // ✅ Переключатель "Мое / Все"
                if (_userDeptId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _showOnlyMyDept ? 'Только мое подразделение' : 'Все новости',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.titleMedium?.color,
                          ),
                        ),
                        Switch(
                          value: _showOnlyMyDept,
                          onChanged: (v) => setState(() => _showOnlyMyDept = v),
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((c) {
                      final isSelected = _selectedCategory == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: isSelected,
                          onSelected: (val) { if (val) setState(() => _selectedCategory = c); },
                          // ✅ Динамические цвета для чипсов
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Theme.of(context).cardColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<News>>(
              stream: _newsService.getNews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Ошибка: ${snapshot.error}'));

                var newsList = snapshot.data ?? [];

                // ✅ Фильтр по подразделению
                if (_showOnlyMyDept && _userDeptId != null) {
                  newsList = newsList.where((n) =>
                  n.departmentId == _userDeptId ||
                      n.departmentId.isEmpty // Пустой ID = общая новость для всех
                  ).toList();
                }

                if (_selectedCategory != 'Все') {
                  newsList = newsList.where((n) => n.category == _selectedCategory).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  newsList = newsList.where((n) =>
                  n.title.toLowerCase().contains(_searchQuery) ||
                      n.body.toLowerCase().contains(_searchQuery)).toList();
                }

                if (newsList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.newspaper,
                          size: 64,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5), // ✅ Динамический цвет
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showOnlyMyDept ? 'Новостей для вашего подразделения пока нет' : 'Новостей пока нет',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodySmall?.color, // ✅ Динамический цвет
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_showOnlyMyDept) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() => _showOnlyMyDept = false),
                            child: const Text('Показать все новости'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: newsList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final news = newsList[i];
                    return GestureDetector(
                      onLongPress: _isAdmin ? () => _showOptionsDialog(news) : null,
                      child: _NewsCard(
                        news: news,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news))).then((_) => setState(() {})),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final News news;
  final VoidCallback onTap;
  const _NewsCard({required this.news, required this.onTap});

  Widget _buildImageWidget() {
    if (news.mainImage.startsWith('http')) {
      return Image.network(news.mainImage, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _placeholder());
    } else {
      try {
        return Image.memory(base64Decode(news.mainImage), fit: BoxFit.contain, errorBuilder: (_, __, ___) => _placeholder());
      } catch (_) {
        return _placeholder();
      }
    }
  }

  Widget _placeholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: AppTheme.lightBlue,
      child: const Center(child: Icon(Icons.newspaper, size: 40, color: AppTheme.accentBlue)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // ✅ Динамический цвет карточки
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (news.hasImage)
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  child: Stack(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400, minHeight: 150),
                        child: SizedBox(width: double.infinity, child: _buildImageWidget()),
                      ),
                      if (news.imageUrls.length > 1)
                        Positioned(
                          top: 10, right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.collections, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text('${news.imageUrls.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17), // ✅ Динамический цвет
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      news.shortDescription,
                      style: Theme.of(context).textTheme.bodySmall, // ✅ Динамический цвет
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}