import 'package:flutter/material.dart';

/// Unikalne kolory do auto-przypisywania kategorii. Używane w kolejności,
/// a gdy wszystkie zajęte – cyklicznie.
class CategoryColors {
  CategoryColors._();

  static const List<String> hexPool = [
    '#4F46E5', // indigo
    '#059669', // emerald
    '#DC2626', // red
    '#D97706', // amber
    '#7C3AED', // violet
    '#0D9488', // teal
    '#DB2777', // pink
    '#2563EB', // blue
    '#CA8A04', // yellow
    '#16A34A', // green
    '#EA580C', // orange
    '#9333EA', // purple
    '#0891B2', // cyan
    '#E11D48', // rose
    '#65A30D', // lime
    '#BE185D', // fuchsia
  ];

  /// Zwraca pierwszy kolor z puli, który nie jest jeszcze używany przez [usedHex].
  /// Jeśli wszystkie używane – zwraca kolor z indeksu [usedHex.length % pool.length].
  static String pickUnused(List<String> usedHex) {
    final used = usedHex.map((h) => _normalize(h)).toSet();
    for (final hex in hexPool) {
      if (!used.contains(_normalize(hex))) return hex;
    }
    return hexPool[usedHex.length % hexPool.length];
  }

  static String _normalize(String hex) {
    final h = hex.replaceFirst('#', '').toUpperCase();
    return '#$h';
  }

  static Color parse(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }
}
