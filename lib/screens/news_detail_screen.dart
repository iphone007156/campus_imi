import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/news_model.dart';

class NewsDetailScreen extends StatelessWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

  Widget _buildImage() {
    if (news.imageUrl.isNotEmpty) {
      return Image.network(
        news.imageUrl,
        fit: BoxFit.cover,
        cacheWidth: 800,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppTheme.lightBlue,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accentBlue,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
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
        child: Icon(Icons.newspaper, size: 60, color: AppTheme.accentBlue),
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Новость'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Поделиться'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.hasImage)
              SizedBox(
                width: double.infinity,
                height: 260,
                child: _buildImage(),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _categoryColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          news.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: _categoryColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time,
                          size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        news.timeAgo,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (news.authorName.isNotEmpty)
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.lightBlue,
                          ),
                          child: const Icon(Icons.person,
                              size: 20, color: AppTheme.accentBlue),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              news.authorName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              news.date,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: AppTheme.divider),
                  const SizedBox(height: 20),
                  Text(
                    news.body,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textDark,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}