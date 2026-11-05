import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../screens/indoor_map_screen.dart';
import '../theme/app_theme.dart';
import 'app_ui.dart';

AppTone lessonTone(String type) {
  switch (type.toLowerCase().trim()) {
    case 'лек':
    case 'лекц':
    case 'лекция':
      return AppTone.accent;
    case 'пр':
    case 'практ':
    case 'практика':
      return AppTone.success;
    case 'лаб':
    case 'лабораторная':
      return AppTone.warning;
    default:
      return AppTone.neutral;
  }
}

String lessonTypeLabel(String type) {
  switch (type.toLowerCase().trim()) {
    case 'лек':
    case 'лекц':
    case 'лекция':
      return 'Лекция';
    case 'пр':
    case 'практ':
    case 'практика':
      return 'Практика';
    case 'лаб':
    case 'лабораторная':
      return 'Лабораторная';
    case 'сем':
    case 'семинар':
      return 'Семинар';
    default:
      return type;
  }
}

/// Начало и конец пары из строки вида «14:00-15:35».
List<String> lessonTimes(Lesson lesson) {
  final matches =
  RegExp(r'(\d{1,2})[:.](\d{2})').allMatches(lesson.time).toList();
  String fmt(RegExpMatch m) =>
      '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}';
  if (matches.isEmpty) return [lesson.time, ''];
  if (matches.length == 1) return [fmt(matches[0]), ''];
  return [fmt(matches[0]), fmt(matches[1])];
}

/// Карточка пары. Нажатие на кабинет открывает карту корпуса.
class LessonTile extends StatelessWidget {
  final Lesson lesson;
  final bool isNow;
  final bool isPast;

  const LessonTile({
    super.key,
    required this.lesson,
    this.isNow = false,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = appIsDark(context);
    final tone = lessonTone(lesson.type);
    final times = lessonTimes(lesson);

    // Цвета блока времени берём из того же набора, что и бейджи.
    Color timeBg;
    Color timeFg;
    switch (tone) {
      case AppTone.accent:
        timeBg = dark ? AppTheme.accentSoftDark : AppTheme.accentSoft;
        timeFg = dark ? AppTheme.accentOnDark : AppTheme.primaryNavy;
        break;
      case AppTone.success:
        timeBg = dark ? const Color(0xFF16352A) : AppTheme.successSoft;
        timeFg = dark ? const Color(0xFF6FD3A0) : AppTheme.success;
        break;
      case AppTone.warning:
        timeBg = dark ? const Color(0xFF3A2E12) : AppTheme.warningSoft;
        timeFg = dark ? const Color(0xFFF2C46D) : AppTheme.warning;
        break;
      default:
        timeBg = dark ? AppTheme.darkSurface : const Color(0xFFEDF0F6);
        timeFg = appMutedColor(context);
    }

    final muted = appMutedColor(context);

    return Opacity(
      opacity: isPast ? 0.6 : 1,
      child: AppCard(
        padding: const EdgeInsets.all(10),
        borderColor: isNow ? appAccentColor(context) : null,
        // ✅ Исправление: используем IntrinsicHeight, чтобы Row не падал
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, // ✅ Теперь безопасно
            children: [
              Container(
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: timeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      times[0],
                      style: TextStyle(
                        color: timeFg,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (times[1].isNotEmpty)
                      Text(
                        times[1],
                        style: TextStyle(
                          color: timeFg,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, // ✅ Прижимаем по центру
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppBadge(lessonTypeLabel(lesson.type), tone: tone),
                        if (isNow) const AppBadge('Сейчас', tone: AppTone.success),
                        if (lesson.week != 0)
                          Text(
                            lesson.week == 1 ? 'нечётная' : 'чётная',
                            style: TextStyle(fontSize: 11, color: muted),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lesson.subject,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lesson.teacher.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lesson.teacher,
                              style: TextStyle(fontSize: 12, color: muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (lesson.room.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => IndoorMapScreen.openForRoom(context, lesson.room),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 32),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 16, color: appAccentColor(context)),
                              const SizedBox(width: 4),
                              Text(
                                'Кабинет ${lesson.room} · на карте',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: appAccentColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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