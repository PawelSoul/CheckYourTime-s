import 'package:intl/intl.dart';

/// Helper do formatowania dat – jeden wspólny format w aplikacji.
class DateTimeUtils {
  DateTimeUtils._();

  static final DateFormat _taskDateTimeFormat =
      DateFormat('dd.MM.yyyy • HH:mm');

  /// Format: "06.02.2026 • 10:09" – używany w liście zadań i szczegółach.
  static String formatTaskDateTime(DateTime dateTime) {
    return _taskDateTimeFormat.format(dateTime);
  }

  /// Z epoch ms (np. z Drift) do stringa w formacie zadania.
  static String formatTaskDateTimeFromEpochMs(int epochMs) {
    return _taskDateTimeFormat.format(DateTime.fromMillisecondsSinceEpoch(epochMs));
  }

  static final DateFormat _dateOnly = DateFormat('dd.MM.yyyy');
  static final DateFormat _timeOnly = DateFormat('HH:mm');
  static final DateFormat _timeWithSeconds = DateFormat('HH:mm:ss');

  static String formatDateFromEpochMs(int epochMs) {
    return _dateOnly.format(DateTime.fromMillisecondsSinceEpoch(epochMs));
  }

  static String formatTimeFromEpochMs(int epochMs) {
    return _timeOnly.format(DateTime.fromMillisecondsSinceEpoch(epochMs));
  }

  /// Godzina z sekundami (np. 18:29:05).
  static String formatTimeWithSecondsFromEpochMs(int epochMs) {
    return _timeWithSeconds.format(DateTime.fromMillisecondsSinceEpoch(epochMs));
  }

  static String formatDate(DateTime d) => _dateOnly.format(d);
  static String formatTime(DateTime d) => _timeOnly.format(d);
  static String formatTimeWithSeconds(DateTime d) => _timeWithSeconds.format(d);

  /// Długość w sekundach → "X min Y s" (np. 125 → "2 min 5 s").
  static String formatDurationSeconds(int totalSec) {
    final min = totalSec ~/ 60;
    final sec = totalSec % 60;
    if (min == 0) return '$sec s';
    if (sec == 0) return '$min min';
    return '$min min $sec s';
  }
}
