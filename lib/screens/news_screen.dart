import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import 'news_detail_screen.dart';
import 'add_news_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'Все';

  static const List<String> _categories = [
    'Все',
    'Trending',
    'Спорт',
    'Учёба',
    'События',
    'Культура',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Новости'),
        actions: [
          // ✅ Кнопка "+" — только для авторизованного админа
          if (FirebaseAuth.instance.currentUser != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data?['role'] == 'admin') {
                    return IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Добавить новость',
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddNewsScreen(),
                          ),
                        );
                        if (result == true) {
                          setState(() {});
                        }
                      },
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // ===== ПОИСК =====
          Container(
            color: AppTheme.cardWhite,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск новостей...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: AppTheme.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // ===== КАТЕГОРИИ =====
          Container(
            color: AppTheme.cardWhite,
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryNavy
                            : AppTheme.backgroundGray,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            color:
                            selected ? Colors.white : AppTheme.textDark,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ===== СПИСОК НОВОСТЕЙ =====
          Expanded(
            child: StreamBuilder<List<News>>(
              stream: _newsService.getNews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text('Ошибка: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                var news = snapshot.data ?? [];

                if (_selectedCategory != 'Все') {
                  news = news
                      .where((n) => n.category == _selectedCategory)
                      .toList();
                }

                if (_searchQuery.isNotEmpty) {
                  news = news.where((n) {
                    return n.title.toLowerCase().contains(_searchQuery) ||
                        n.body.toLowerCase().contains(_searchQuery) ||
                        n.shortDescription
                            .toLowerCase()
                            .contains(_searchQuery);
                  }).toList();
                }

                if (news.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: news.length,
                  itemBuilder: (context, i) => _NewsCard(
                    news: news[i],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewsDetailScreen(news: news[i]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? Icons.search_off
                : Icons.newspaper_outlined,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Ничего не найдено'
                : 'Новостей пока нет',
            style: const TextStyle(fontSize: 18, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Попробуйте другой запрос'
                : 'Загляните позже',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== КАРТОЧКА НОВОСТИ =====
class _NewsCard extends StatelessWidget {
  final News news;
  final VoidCallback onTap;

  const _NewsCard({required this.news, required this.onTap});

  Widget _buildImage() {
    if (news.imageUrl.isNotEmpty) {
      return Image.network(
        news.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    if (news.imageBase64.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(news.imageBase64),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      } catch (e) {
        return _buildPlaceholder();
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.lightBlue,
      child: const Center(
        child: Icon(Icons.newspaper, size: 40, color: AppTheme.accentBlue),
      ),
    );
  }

  Color get _categoryColor {
    switch (news.category) {
      case 'Trending':
        return Colors.red;
      case 'Спорт':
        return Colors.orange;
      case 'Учёба':
        return AppTheme.accentBlue;
      case 'События':
        return Colors.purple;
      case 'Культура':
        return Colors.teal;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (news.hasImage)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: _buildImage(),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            news.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              color: _categoryColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.access_time,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          news.timeAgo,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Text(
                      news.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    Text(
                      news.shortDescription.isNotEmpty
                          ? news.shortDescription
                          : news.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        if (news.authorName.isNotEmpty) ...[
                          const Icon(Icons.person,
                              size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            news.authorName,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                        const Spacer(),
                        const Text(
                          'Читать',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppTheme.accentBlue),
                      ],
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