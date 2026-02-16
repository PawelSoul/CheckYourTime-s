/// Rodzaj filtra czasowego listy zadań.
enum TasksDateFilterKind {
  all,
  today,
  last7,
  last30,
  month,
  year,
}

/// Stan filtra czasowego: rodzaj + opcjonalnie rok i miesiąc (dla month/year).
class TasksDateFilterState {
  const TasksDateFilterState({
    required this.kind,
    this.year,
    this.month,
  });

  final TasksDateFilterKind kind;
  final int? year;
  final int? month; // 1-12

  static TasksDateFilterState get all => const TasksDateFilterState(kind: TasksDateFilterKind.all);

  static TasksDateFilterState get today => const TasksDateFilterState(kind: TasksDateFilterKind.today);

  static TasksDateFilterState get last7 => const TasksDateFilterState(kind: TasksDateFilterKind.last7);

  static TasksDateFilterState get last30 => const TasksDateFilterState(kind: TasksDateFilterKind.last30);

  static TasksDateFilterState forMonth(int y, int m) =>
      TasksDateFilterState(kind: TasksDateFilterKind.month, year: y, month: m);

  static TasksDateFilterState forYear(int y) =>
      TasksDateFilterState(kind: TasksDateFilterKind.year, year: y);

  /// Czy [createdAtMs] (Unix epoch ms) mieści się w zakresie tego filtra.
  bool contains(int createdAtMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (kind) {
      case TasksDateFilterKind.all:
        return true;
      case TasksDateFilterKind.today:
        final taskDay = DateTime(dt.year, dt.month, dt.day);
        return taskDay == todayStart;
      case TasksDateFilterKind.last7:
        final rangeStart = todayStart.subtract(const Duration(days: 6));
        final taskDay = DateTime(dt.year, dt.month, dt.day);
        return !taskDay.isBefore(rangeStart) && !taskDay.isAfter(todayStart);
      case TasksDateFilterKind.last30:
        final rangeStart = todayStart.subtract(const Duration(days: 29));
        final taskDay = DateTime(dt.year, dt.month, dt.day);
        return !taskDay.isBefore(rangeStart) && !taskDay.isAfter(todayStart);
      case TasksDateFilterKind.month:
        return year != null && month != null && dt.year == year && dt.month == month;
      case TasksDateFilterKind.year:
        return year != null && dt.year == year;
    }
  }

  /// Zwraca zakres [fromMs, toMs] (Unix epoch ms) dla tego filtra.
  /// [toMs] jest exclusive (koniec zakresu + 1 ms).
  ({int fromMs, int toMs}) get timeRangeMs {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (kind) {
      case TasksDateFilterKind.all:
        return (fromMs: 0, toMs: todayEnd.millisecondsSinceEpoch + 1);
      case TasksDateFilterKind.today:
        final start = DateTime(now.year, now.month, now.day);
        return (fromMs: start.millisecondsSinceEpoch, toMs: todayEnd.millisecondsSinceEpoch + 1);
      case TasksDateFilterKind.last7:
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        return (fromMs: start.millisecondsSinceEpoch, toMs: todayEnd.millisecondsSinceEpoch + 1);
      case TasksDateFilterKind.last30:
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
        return (fromMs: start.millisecondsSinceEpoch, toMs: todayEnd.millisecondsSinceEpoch + 1);
      case TasksDateFilterKind.month:
        if (year != null && month != null) {
          final start = DateTime(year!, month!, 1);
          final end = DateTime(year!, month! + 1, 0, 23, 59, 59, 999);
          return (fromMs: start.millisecondsSinceEpoch, toMs: end.millisecondsSinceEpoch + 1);
        }
        return (fromMs: 0, toMs: todayEnd.millisecondsSinceEpoch + 1);
      case TasksDateFilterKind.year:
        if (year != null) {
          final start = DateTime(year!, 1, 1);
          final end = DateTime(year!, 12, 31, 23, 59, 59, 999);
          return (fromMs: start.millisecondsSinceEpoch, toMs: end.millisecondsSinceEpoch + 1);
        }
        return (fromMs: 0, toMs: todayEnd.millisecondsSinceEpoch + 1);
    }
  }
}
