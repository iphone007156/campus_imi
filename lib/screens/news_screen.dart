import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NewsItem {
  final String title;
  final String body;
  final String date;
  final IconData icon;

  const NewsItem({
    required this.title,
    required this.body,
    required this.date,
    required this.icon,
  });
}

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  static const List<NewsItem> _news = [
    NewsItem(
      title: 'Научная конференция ИМИ 2024',
      body: 'Приглашаем студентов и преподавателей принять участие',
      date: '12 дек',
      icon: Icons.science_outlined,
    ),
    NewsItem(
      title: 'Итоги олимпиады по математике',
      body: 'Студенты ИМИ заняли призовые места в республиканской олимпиаде',
      date: '8 дек',
      icon: Icons.emoji_events_outlined,
    ),
    NewsItem(
      title: 'Обновление расписания',
      body: 'В расписании на следующую неделю произведены изменения',
      date: '5 дек',
      icon: Icons.calendar_today_outlined,
    ),
    NewsItem(
      title: 'День открытых дверей',
      body: 'Приглашаем абитуриентов познакомиться с институтом',
      date: '1 дек',
      icon: Icons.door_front_door_outlined,
    ),
    NewsItem(
      title: 'Стипендиальная программа',
      body: 'Открыт приём заявок на повышенную стипендию',
      date: '28 ноя',
      icon: Icons.attach_money_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Новости'),
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _news.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _NewsCard(item: _news[i]),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;

  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: AppTheme.accentBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.date,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}