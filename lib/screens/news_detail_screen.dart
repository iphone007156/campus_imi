import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/news_model.dart';
import 'add_news_screen.dart';
import 'full_screen_image_screen.dart';

class NewsDetailScreen extends StatefulWidget {
  final News news;
  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?['role'] == 'admin') {
        if (mounted) setState(() => _isAdmin = true);
      }
    }
  }

  Color get _categoryColor {
    switch (widget.news.category) {
      case 'Trending': return Colors.red;
      case 'Спорт': return Colors.orange;
      case 'Учёба': return AppTheme.accentBlue;
      case 'События': return Colors.purple;
      case 'Культура': return Colors.teal;
      default: return AppTheme.textMuted;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String url, {BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: fit,
        filterQuality: FilterQuality.high,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
        errorBuilder: (_, __, ___) => Container(color: AppTheme.lightBlue),
      );
    }
    return Image.memory(
      base64Decode(url),
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Container(color: AppTheme.lightBlue),
    );
  }

  Widget _buildImageCarousel() {
    final urls = widget.news.imageUrls;
    if (urls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: urls.length,
            itemBuilder: (context, index) {
              final url = urls[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageScreen(
                        imageUrl: url,
                        isBase64: !url.startsWith('http'),
                      ),
                    ),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: _buildImageWidget(url, fit: BoxFit.cover),
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildImageWidget(url, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (urls.length > 1)
            Positioned(
              bottom: 12, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Новость'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Редактировать',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddNewsScreen(news: widget.news)),
                );
                if (result == true && mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.news.hasImage) _buildImageCarousel(),
            Padding(
              padding: const EdgeInsets.all(AppTheme.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                            widget.news.category.toUpperCase(),
                            style: TextStyle(fontSize: 10, color: _categoryColor, fontWeight: FontWeight.w800)
                        ),
                      ),
                      const SizedBox(width: AppTheme.s8),
                      Icon(Icons.access_time, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text(widget.news.timeAgo, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppTheme.s16),
                  Text(
                    widget.news.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24, height: 1.2), // ✅
                  ),
                  const SizedBox(height: AppTheme.s16),
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), // ✅
                        ),
                        child: Icon(Icons.person, size: 22, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: AppTheme.s12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.news.authorName, style: Theme.of(context).textTheme.titleMedium),
                          Text(widget.news.date, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.s24),
                  Divider(color: Theme.of(context).dividerColor), // ✅
                  const SizedBox(height: AppTheme.s24),
                  Text(
                    widget.news.body,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6), // ✅
                  ),

                  if (widget.news.hasSource)
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor, // ✅
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor), // ✅
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.source, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
                                const SizedBox(width: 8),
                                Text('Источник', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (widget.news.sourceName.isNotEmpty)
                              Text(widget.news.sourceName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                            if (widget.news.sourceUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GestureDetector(
                                  onTap: () async {
                                    final url = Uri.parse(widget.news.sourceUrl);
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: Text(
                                    widget.news.sourceUrl,
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}