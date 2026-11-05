import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ Подключаем пакет

class AppTheme {
  // ── Палитра (Светлая) ──────────────────────────────
  static const Color primaryNavy = Color(0xFF1A2A5E);
  static const Color accentBlue = Color(0xFF3D6FA3);
  static const Color accent = Color(0xFFFF6B35);
  static const Color lightBlue = Color(0xFFD6E4F0);
  static const Color backgroundGray = Color(0xFFF7F9FC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1C2B3A);
  static const Color textMuted = Color(0xFF56657F); // контраст не ниже 4,5:1 на светлом фоне
  static const Color gold = Color(0xFFB8922A);
  static const Color divider = Color(0xFFDDE6EF);

  // ── Семантические цвета нового дизайна ─────────────
  static const Color accentSoft = Color(0xFFE6EBF8);
  static const Color accentSoftDark = Color(0xFF22305E);
  static const Color accentOnDark = Color(0xFF8EA4F0);
  static const Color success = Color(0xFF1B6E45);
  static const Color successSoft = Color(0xFFE1F3E9);
  static const Color warning = Color(0xFF8A5A00);
  static const Color warningSoft = Color(0xFFFBEFD5);
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerSoft = Color(0xFFFBE7E4);

  // ── Палитра (Тёмная) ───────────────────────────────
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF2C2C2C);
  static const Color darkText = Color(0xFFE8E8E8);
  static const Color darkTextMuted = Color(0xFFA3AEC7);
  static const Color darkDivider = Color(0xFF333333);

  // ── Радиусы ────────────────────────────────────────
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusPill = 999;

  // ── Отступы ────────────────────────────────────────
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;

  // ── Тени ───────────────────────────────────────────
  static List<BoxShadow> get shadowSoft => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  // ── Тема ───────────────────────────────────────────
  static ThemeData get theme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? darkBg : backgroundGray;
    final card = isDark ? darkCard : cardWhite;
    final txt = isDark ? darkText : textDark;
    final muted = isDark ? darkTextMuted : textMuted;
    final div = isDark ? darkDivider : divider;

    // ✅ Применяем базовый шрифт Manrope (аналог SF Pro)
    final baseTextTheme = GoogleFonts.manropeTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        brightness: brightness,
        surface: card,
        background: bg,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: card,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkCard : primaryNavy,
        foregroundColor: isDark ? darkText : Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.manrope( // ✅ Заголовок AppBar (как в iOS)
          color: isDark ? darkText : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4, // Сжимаем буквы для "яблочного" стиля
        ),
      ),

      // ✅ Настраиваем типографику
      textTheme: baseTextTheme.copyWith(
        headlineSmall: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: txt,
          letterSpacing: -0.8, // Плотная посадка
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: txt,
          letterSpacing: -0.4,
        ),
        titleSmall: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: txt,
          letterSpacing: -0.2,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 15,
          height: 1.45, // Идеальный интервал для чтения
          color: txt,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 13,
          color: muted,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: muted,
          letterSpacing: 0.8,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? accentBlue : primaryNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? accent : primaryNavy,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: div, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface : card,
        contentPadding: const EdgeInsets.symmetric(horizontal: s16, vertical: s16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: BorderSide(color: div)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: const BorderSide(color: accent, width: 1.5)),
        hintStyle: GoogleFonts.manrope(color: muted, fontSize: 15),
        labelStyle: GoogleFonts.manrope(color: muted, fontSize: 15),
      ),

      // ✅ ГЛОБАЛЬНЫЙ СТИЛЬ ВКЛАДОК (БЕЗ ОВАЛОВ)
      tabBarTheme: TabBarThemeData(
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 3.0,
            color: isDark ? gold : Colors.white,
          ),
        ),
        labelColor: isDark ? darkText : Colors.white,
        unselectedLabelColor: isDark ? darkTextMuted : Colors.white70,
        labelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        dividerColor: Colors.transparent,
      ),

      // ✅ Нижняя навигация нового дизайна
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: isDark ? accentSoftDark : accentSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? (isDark ? accentOnDark : primaryNavy) : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? (isDark ? accentOnDark : primaryNavy) : muted,
          );
        }),
      ),

      dividerTheme: DividerThemeData(color: div, thickness: 1, space: 1),
    );
  }
}