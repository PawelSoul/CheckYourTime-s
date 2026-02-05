import 'package:flutter/material.dart';

class AppTheme {
  static const _seedLight = Colors.blue;
  static const _seedDark = Colors.blueAccent;

  static final light = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _seedLight,
    brightness: Brightness.light,
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
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _seedDark,
      unselectedItemColor: Colors.grey.shade400,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
