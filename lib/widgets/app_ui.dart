import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Общие компоненты нового дизайна. Используйте их на всех экранах,
/// чтобы карточки, бейджи, пустые состояния и списки выглядели одинаково.

bool appIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color appLineColor(BuildContext context) =>
    appIsDark(context) ? AppTheme.darkDivider : AppTheme.divider;

Color appMutedColor(BuildContext context) =>
    appIsDark(context) ? AppTheme.darkTextMuted : AppTheme.textMuted;

Color appAccentColor(BuildContext context) =>
    appIsDark(context) ? AppTheme.accentOnDark : AppTheme.primaryNavy;

Color appAccentSoftColor(BuildContext context) =>
    appIsDark(context) ? AppTheme.accentSoftDark : AppTheme.accentSoft;

enum AppTone { neutral, accent, success, warning, danger }

class _ToneColors {
  final Color background;
  final Color foreground;
  const _ToneColors(this.background, this.foreground);
}

_ToneColors _toneColors(BuildContext context, AppTone tone) {
  final dark = appIsDark(context);
  switch (tone) {
    case AppTone.accent:
      return _ToneColors(
        dark ? AppTheme.accentSoftDark : AppTheme.accentSoft,
        dark ? AppTheme.accentOnDark : AppTheme.primaryNavy,
      );
    case AppTone.success:
      return _ToneColors(
        dark ? const Color(0xFF16352A) : AppTheme.successSoft,
        dark ? const Color(0xFF6FD3A0) : AppTheme.success,
      );
    case AppTone.warning:
      return _ToneColors(
        dark ? const Color(0xFF3A2E12) : AppTheme.warningSoft,
        dark ? const Color(0xFFF2C46D) : AppTheme.warning,
      );
    case AppTone.danger:
      return _ToneColors(
        dark ? const Color(0xFF3B1E1C) : AppTheme.dangerSoft,
        dark ? const Color(0xFFF2958E) : AppTheme.danger,
      );
    case AppTone.neutral:
      return _ToneColors(
        dark ? AppTheme.darkSurface : const Color(0xFFEDF0F6),
        appMutedColor(context),
      );
  }
}

/// Карточка: белый фон, тонкая линия, без теней.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.s12),
    this.onTap,
    this.borderColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Material(
      color: color ?? Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor ?? appLineColor(context), width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Подпись раздела над группой карточек.
class AppSectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  const AppSectionLabel(
      this.text, {
        super.key,
        this.padding = const EdgeInsets.fromLTRB(4, AppTheme.s16, 4, AppTheme.s8),
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: appMutedColor(context),
        ),
      ),
    );
  }
}

/// Небольшой цветной статус: «Решено», «В работе», «Практика».
class AppBadge extends StatelessWidget {
  final String text;
  final AppTone tone;
  final IconData? icon;
  const AppBadge(this.text, {super.key, this.tone = AppTone.neutral, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = _toneColors(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: c.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Иконка в цветной плитке (для строк списка и быстрых действий).
class AppIconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final AppTone tone;
  const AppIconBox(this.icon, {super.key, this.size = 40, this.tone = AppTone.accent});

  @override
  Widget build(BuildContext context) {
    final c = _toneColors(context, tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: size * 0.52, color: c.foreground),
    );
  }
}

/// Фильтр-чип (категории новостей и т.п.). Минимальная высота нажатия 40.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const AppChip({super.key, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = appIsDark(context);
    final bg = selected
        ? (dark ? AppTheme.accentOnDark : AppTheme.primaryNavy)
        : Theme.of(context).cardColor;
    final fg = selected
        ? (dark ? const Color(0xFF0B1230) : Colors.white)
        : Theme.of(context).textTheme.bodyMedium?.color;
    return Material(
      color: bg,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? bg : appLineColor(context), width: 0.8),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Переключатель из 2–3 вариантов («Эта неделя | Следующая»).
class AppSegmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const AppSegmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dark = appIsDark(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: dark ? AppTheme.accentSoftDark : AppTheme.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? Theme.of(context).cardColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                      color: i == index
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : appMutedColor(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Строка списка: плитка с иконкой, заголовок, подпись, стрелка.
class AppListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final AppTone tone;
  const AppListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.tone = AppTone.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.s12, vertical: 8),
          child: Row(
            children: [
              AppIconBox(icon, tone: tone),
              const SizedBox(width: AppTheme.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12, color: appMutedColor(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              trailing ??
                  (onTap != null
                      ? Icon(Icons.chevron_right, size: 20, color: appMutedColor(context))
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Пустое состояние: название места, одна строка пояснения, действие.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appAccentSoftColor(context),
              ),
              child: Icon(icon, size: 32, color: appAccentColor(context)),
            ),
            const SizedBox(height: AppTheme.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: appMutedColor(context)),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.s16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ошибка загрузки с кнопкой «Повторить».
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppErrorState({super.key, this.message = 'Не удалось загрузить данные', this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.cloud_off_outlined,
      title: message,
      message: 'Проверьте подключение к интернету и попробуйте ещё раз.',
      actionLabel: onRetry == null ? null : 'Повторить',
      onAction: onRetry,
    );
  }
}

/// Ручка нижней шторки.
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: appLineColor(context),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
