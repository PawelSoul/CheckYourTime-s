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

  static String formatDateFromEpochMs(int epochMs) {
    return _dateOnly.format(DateTime.fromMillisecondsSinceEpoch(epochMs));
  }

  static String formatTimeFromEpochMs(int epochMs) {
    return _timeOnly.format(DateTime.fromMillisecondsSinceEpoch(epochMs));
  }

  static String formatDate(DateTime d) => _dateOnly.format(d);
  static String formatTime(DateTime d) => _timeOnly.format(d);
}
