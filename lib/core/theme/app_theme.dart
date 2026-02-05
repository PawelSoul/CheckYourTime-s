import 'package:flutter/material.dart';

class AppTheme {
  static const _seedLight = Colors.blue;
  static const _seedDark = Colors.blueAccent;

  static final light = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _seedLight,
    brightness: Brightness.light,
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _seedDark,
    brightness: Brightness.dark,
  );
}
