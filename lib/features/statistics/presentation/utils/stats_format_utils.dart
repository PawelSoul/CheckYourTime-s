import 'package:checkyourtime/features/statistics/domain/models/statistics_models.dart';

/// Narzędzia do formatowania wartości statystyk.
class StatsFormatUtils {
  StatsFormatUtils._();

  /// Formatuje sekundy jako "HHh MMm" (np. 3661 → "1h 1m").
  static String formatTotalTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours == 0) {
      return '${minutes}m';
    }
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  /// Formatuje sekundy jako "X min Y s" lub "X min".
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes == 0) return '${secs}s';
    if (secs == 0) return '${minutes}min';
    return '${minutes}min ${secs}s';
  }

  /// Formatuje dzień tygodnia (1=Mon → "Poniedziałek").
  static String formatWeekday(int weekday) {
    const days = [
      'Poniedziałek',
      'Wtorek',
      'Środa',
      'Czwartek',
      'Piątek',
      'Sobota',
      'Niedziela',
    ];
    return days[weekday - 1];
  }

  /// Formatuje dzień tygodnia krótko (1=Mon → "Pon").
  static String formatWeekdayShort(int weekday) {
    const days = ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sb', 'Nd'];
    return days[weekday - 1];
  }

  /// Formatuje datę jako "DD.MM" (np. "13.02").
  static String formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  /// Formatuje datę jako "DD.MM.YYYY".
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
