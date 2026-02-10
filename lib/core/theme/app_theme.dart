import 'package:flutter/material.dart';

class AppTheme {
  static const _seedLight = Colors.blue;
  static const _seedDark = Colors.blueAccent;

  static final light = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _seedLight,
    brightness: Brightness.light,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _seedLight,
      unselectedItemColor: Colors.grey.shade600,
      type: BottomNavigationBarType.fixed,
    ),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _seedDark,
    brightness: Brightness.dark,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.black87,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _seedDark,
      unselectedItemColor: Colors.grey.shade400,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
