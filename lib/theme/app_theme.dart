import 'package:flutter/material.dart';

class AppTheme {
  // Цветовая палитра СВФУ (тёмно-синий университетский стиль)
  static const Color primaryNavy = Color(0xFF1A2A5E);
  static const Color accentBlue = Color(0xFF3D6FA3);
  static const Color lightBlue = Color(0xFFD6E4F0);
  static const Color backgroundGray = Color(0xFFF0F4F8);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1C2B3A);
  static const Color textMuted = Color(0xFF7A92A8);
  static const Color gold = Color(0xFFB8922A);
  static const Color divider = Color(0xFFDDE6EF);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryNavy,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundGray,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cardWhite,
        foregroundColor: primaryNavy,
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: divider),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
