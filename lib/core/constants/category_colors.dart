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

  /// Zamienia hex string (np. "#FFAA00" lub "FFAA00") na [Color].
  /// Obsługuje: z/bez '#', 6 znaków (RGB) lub 8 znaków (ARGB).
  /// Dla null, pustego lub nieprawidłowego stringa zwraca [Colors.grey].
  static Color parse(String? hex) {
    if (hex == null || hex.trim().isEmpty) return Colors.grey;
    String h = hex.trim().replaceFirst('#', '');
    if (h.isEmpty) return Colors.grey;
    if (h.length == 6) {
      h = 'FF$h'; // domyślna pełna nieprzezroczystość
    }
    if (h.length != 8) return Colors.grey;
    try {
      final value = int.parse(h, radix: 16);
      return Color(value);
    } catch (_) {
      return Colors.grey;
    }
  }
}
