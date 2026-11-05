import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../models/news_model.dart';
import 'news_detail_screen.dart';
import 'add_news_screen.dart';
import '../services/news_service.dart';

class NewsScreen extends StatefulWidget {
  /// true — экран внутри нижней навигации (без стрелки «назад»).
  final bool embedded;
  const NewsScreen({super.key, this.embedded = false});

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
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
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
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск новостей',
                    prefixIcon: Icon(Icons.search, color: appMutedColor(context)),
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // «Моё подразделение» — один чип вместо отдельной строки с переключателем.
                      if (_userDeptId != null) ...[
                        AppChip(
                          label: 'Моё подразделение',
                          selected: _showOnlyMyDept,
                          onTap: () => setState(() => _showOnlyMyDept = !_showOnlyMyDept),
                        ),
                        const SizedBox(width: 8),
                      ],
                      for (final c in _categories) ...[
                        AppChip(
                          label: c,
                          selected: _selectedCategory == c,
                          onTap: () => setState(() => _selectedCategory = c),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
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
                if (snapshot.hasError) return AppErrorState(onRetry: () => setState(() {}));

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
                  return AppEmptyState(
                    icon: Icons.newspaper_outlined,
                    title: _showOnlyMyDept
                        ? 'Новостей для вашего подразделения пока нет'
                        : 'Новостей пока нет',
                    message: _searchQuery.isNotEmpty || _selectedCategory != 'Все'
                        ? 'Попробуйте изменить поиск или категорию'
                        : null,
                    actionLabel: _showOnlyMyDept ? 'Показать все новости' : null,
                    onAction: _showOnlyMyDept ? () => setState(() => _showOnlyMyDept = false) : null,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: newsList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
      return Image.network(
        news.mainImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    try {
      return Image.memory(
        base64Decode(news.mainImage),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.accentSoft,
      child: const Center(
        child: Icon(Icons.photo_outlined, size: 36, color: AppTheme.primaryNavy),
      ),
    );
  }

  AppTone _categoryTone(String category) {
    switch (category) {
      case 'Спорт':
        return AppTone.warning;
      case 'Учёба':
        return AppTone.success;
      case 'Trending':
        return AppTone.danger;
      default:
        return AppTone.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = appMutedColor(context);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (news.hasImage)
          // Фиксированное соотношение сторон: картинки не «прыгают» по высоте.
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageWidget(),
                  if (news.imageUrls.length > 1)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.collections, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${news.imageUrls.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (news.category.isNotEmpty)
                      AppBadge(news.category, tone: _categoryTone(news.category)),
                    if (news.category.isNotEmpty && news.date.isNotEmpty)
                      const SizedBox(width: 8),
                    if (news.date.isNotEmpty)
                      Text(news.date, style: TextStyle(fontSize: 12, color: muted)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  news.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (news.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    news.shortDescription,
                    style: TextStyle(fontSize: 13, color: muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
