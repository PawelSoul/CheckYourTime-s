import 'package:checkyourtime/data/db/daos/categories_dao.dart';
import 'package:checkyourtime/data/db/daos/sessions_dao.dart';
import 'package:checkyourtime/data/db/daos/tasks_dao.dart';
import 'package:checkyourtime/features/statistics/domain/models/statistics_models.dart';
import 'package:checkyourtime/features/statistics/domain/stats_widget_key.dart';

/// Serwis do obliczania statystyk kategorii.
class StatisticsService {
  StatisticsService({
    required SessionsDao sessionsDao,
    required TasksDao tasksDao,
    required CategoriesDao categoriesDao,
  })  : _sessionsDao = sessionsDao,
        _tasksDao = tasksDao,
        _categoriesDao = categoriesDao;

  final SessionsDao _sessionsDao;
  final TasksDao _tasksDao;
  final CategoriesDao _categoriesDao;

  /// Pobiera wszystkie zakończone sesje dla kategorii w zakresie.
  Future<List<SessionWithTask>> _getCompletedSessionsForCategory(
    String categoryId,
    StatsRange range,
  ) async {
    final now = DateTime.now();
    int fromMs;
    int toMs = now.millisecondsSinceEpoch + 1;

    switch (range) {
      case StatsRange.all:
        fromMs = 0;
        break;
      case StatsRange.thisMonth:
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        fromMs = firstDayOfMonth.millisecondsSinceEpoch;
        break;
    }

    final allSessions = await _sessionsDao.getSessionsWithTasksInRange(
      fromMs: fromMs,
      toMs: toMs,
    );

    // Filtruj tylko sesje z zadaniami w tej kategorii i zakończone (endAt != null)
    return allSessions.where((swt) {
      return swt.task.categoryId == categoryId && swt.session.endAt != null;
    }).toList();
  }

  /// Oblicza statystyki kategorii.
  Future<CategoryStats> getCategoryStats(
    String categoryId,
    StatsRange range,
  ) async {
    final sessions = await _getCompletedSessionsForCategory(categoryId, range);

    final totalTimeSeconds = sessions.fold<int>(
      0,
      (sum, swt) => sum + (swt.session.durationSec as int),
    );

    final averageSessionDurationSeconds = sessions.isEmpty
        ? 0.0
        : totalTimeSeconds / sessions.length;

    final last7Days = _calculateLast7Days(sessions);
    final trend30Days = await _calculateTrend30Days(categoryId);
    final mostProductiveWeekday = _calculateMostProductiveWeekday(sessions, range);
    final streak = _calculateStreak(sessions, range);
    final peakHourResult = _calculatePeakHour(sessions);
    final peakHourRange = peakHourResult.peakRange;
    final hourHistogram = peakHourResult.histogram;
    final shareVsAverage = await _calculateShareVsAverage(categoryId, range);

    return CategoryStats(
      categoryId: categoryId,
      totalTimeSeconds: totalTimeSeconds,
      averageSessionDurationSeconds: averageSessionDurationSeconds,
      last7Days: last7Days,
      trend30Days: trend30Days,
      mostProductiveWeekday: mostProductiveWeekday,
      streak: streak,
      peakHourRange: peakHourRange,
      hourHistogram: hourHistogram,
      shareVsAverage: shareVsAverage,
    );
  }

  /// Ostatnie 7 dni (suma minut per dzień).
  List<DayBucket> _calculateLast7Days(List<SessionWithTask> sessions) {
    final now = DateTime.now();
    final buckets = <DateTime, DayBucket>{};

    // Inicjalizuj ostatnie 7 dni (od najstarszego do najnowszego)
    for (var i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      buckets[date] = DayBucket(
        date: date,
        totalMinutes: 0,
        sessionCount: 0,
      );
    }

    // Grupuj sesje po dniu
    for (final swt in sessions) {
      final sessionDate = DateTime.fromMillisecondsSinceEpoch(swt.session.startAt);
      final dayStart = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
      final minutes = swt.session.durationSec ~/ 60;

      if (buckets.containsKey(dayStart)) {
        final existing = buckets[dayStart]!;
        buckets[dayStart] = DayBucket(
          date: existing.date,
          totalMinutes: existing.totalMinutes + minutes,
          sessionCount: existing.sessionCount + 1,
        );
      }
    }

    return buckets.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Trend ostatnich 30 dni vs poprzednie 30 dni.
  Future<TrendData?> _calculateTrend30Days(String categoryId) async {
    final now = DateTime.now();
    final current30Start = now.subtract(const Duration(days: 30));
    final previous30Start = now.subtract(const Duration(days: 60));
    final previous30End = current30Start;

    final currentSessions = await _sessionsDao.getSessionsWithTasksInRange(
      fromMs: current30Start.millisecondsSinceEpoch,
      toMs: now.millisecondsSinceEpoch + 1,
    );
    final currentFiltered = currentSessions
        .where((swt) => swt.task.categoryId == categoryId && swt.session.endAt != null)
        .toList();

    final previousSessions = await _sessionsDao.getSessionsWithTasksInRange(
      fromMs: previous30Start.millisecondsSinceEpoch,
      toMs: previous30End.millisecondsSinceEpoch,
    );
    final previousFiltered = previousSessions
        .where((swt) => swt.task.categoryId == categoryId && swt.session.endAt != null)
        .toList();

    if (currentFiltered.isEmpty && previousFiltered.isEmpty) return null;

    final current30Days = _bucketByDays(currentFiltered, current30Start, now);
    final previous30Days = _bucketByDays(previousFiltered, previous30Start, previous30End);

    return TrendData(
      current30Days: current30Days,
      previous30Days: previous30Days,
    );
  }

  /// Grupuje sesje po dniach w zakresie.
  List<DayBucket> _bucketByDays(
    List<SessionWithTask> sessions,
    DateTime from,
    DateTime to,
  ) {
    final buckets = <DateTime, DayBucket>{};
    var current = DateTime(from.year, from.month, from.day);

    while (current.isBefore(to) || current.isAtSameMomentAs(DateTime(to.year, to.month, to.day))) {
      buckets[current] = DayBucket(
        date: current,
        totalMinutes: 0,
        sessionCount: 0,
      );
      current = current.add(const Duration(days: 1));
    }

    for (final swt in sessions) {
      final sessionDate = DateTime.fromMillisecondsSinceEpoch(swt.session.startAt);
      final dayStart = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
      final minutes = swt.session.durationSec ~/ 60;

      if (buckets.containsKey(dayStart)) {
        final existing = buckets[dayStart]!;
        buckets[dayStart] = DayBucket(
          date: existing.date,
          totalMinutes: existing.totalMinutes + minutes,
          sessionCount: existing.sessionCount + 1,
        );
      }
    }

    return buckets.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Najbardziej produktywny dzień tygodnia (1=Mon, 7=Sun).
  int? _calculateMostProductiveWeekday(
    List<SessionWithTask> sessions,
    StatsRange range,
  ) {
    if (sessions.isEmpty) return null;

    final weekdayTotals = <int, int>{}; // 1-7

    for (final swt in sessions) {
      final sessionDate = DateTime.fromMillisecondsSinceEpoch(swt.session.startAt);
      final weekday = sessionDate.weekday; // 1=Mon, 7=Sun
      final minutes = swt.session.durationSec ~/ 60;
      weekdayTotals[weekday] = (weekdayTotals[weekday] ?? 0) + minutes;
    }

    if (weekdayTotals.isEmpty) return null;

    int? maxWeekday;
    int maxMinutes = 0;
    weekdayTotals.forEach((weekday, minutes) {
      if (minutes > maxMinutes) {
        maxMinutes = minutes;
        maxWeekday = weekday;
      }
    });

    return maxWeekday;
  }

  /// Oblicza streak dni (minimum 2 sesje i >= 10 minut dziennie).
  int _calculateStreak(List<SessionWithTask> sessions, StatsRange range) {
    if (sessions.isEmpty) return 0;

    // Grupuj sesje po dniach
    final daySessions = <DateTime, List<SessionWithTask>>{};
    for (final swt in sessions) {
      final sessionDate = DateTime.fromMillisecondsSinceEpoch(swt.session.startAt);
      final dayStart = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
      daySessions.putIfAbsent(dayStart, () => []).add(swt);
    }

    // Sprawdź które dni spełniają warunki
    final validDays = <DateTime>{};
    daySessions.forEach((day, daySessionsList) {
      final sessionCount = daySessionsList.length;
      final totalMinutes = daySessionsList.fold<int>(
        0,
        (sum, swt) => sum + (swt.session.durationSec ~/ 60),
      );
      if (sessionCount >= 2 && totalMinutes >= 10) {
        validDays.add(day);
      }
    });

    if (validDays.isEmpty) return 0;

    // Oblicz streak wstecz od dziś lub od ostatniego dnia w zakresie
    final now = DateTime.now();
    DateTime? endDate;
    if (range == StatsRange.thisMonth) {
      endDate = DateTime(now.year, now.month, now.day);
    } else {
      // Dla "Wszystkie" - od ostatniego dnia z aktywnością
      final sortedDays = validDays.toList()..sort((a, b) => b.compareTo(a));
      endDate = sortedDays.first;
    }

    int streak = 0;
    var current = endDate!;
    while (validDays.contains(current)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
      // Dla "Ten miesiąc" - nie wychodź poza miesiąc
      if (range == StatsRange.thisMonth &&
          current.month != endDate.month) {
        break;
      }
    }

    return streak;
  }

  /// Najczęstsza godzina pracy (histogram 0-23).
  _PeakHourResult _calculatePeakHour(List<SessionWithTask> sessions) {
    final hourCounts = List<int>.filled(24, 0);

    for (final swt in sessions) {
      final sessionDate = DateTime.fromMillisecondsSinceEpoch(swt.session.startAt);
      final hour = sessionDate.hour;
      hourCounts[hour]++;
    }

    final histogram = List.generate(24, (i) => HourBucket(hour: i, sessionCount: hourCounts[i]));

    // Znajdź godzinę z max count
    int maxCount = 0;
    int? maxHour;
    for (var i = 0; i < 24; i++) {
      if (hourCounts[i] > maxCount) {
        maxCount = hourCounts[i];
        maxHour = i;
      }
    }

    String? peakRange;
    if (maxHour != null && maxCount > 0) {
      final nextHour = (maxHour + 1) % 24;
      peakRange = '${maxHour.toString().padLeft(2, '0')}:00-${nextHour.toString().padLeft(2, '0')}:00';
    }

    return _PeakHourResult(peakRange: peakRange, histogram: histogram);
  }

  /// Udział kategorii vs średnia wszystkich kategorii.
  Future<ShareVsAverage?> _calculateShareVsAverage(
    String categoryId,
    StatsRange range,
  ) async {
    final now = DateTime.now();
    int fromMs;
    int toMs = now.millisecondsSinceEpoch + 1;

    switch (range) {
      case StatsRange.all:
        fromMs = 0;
        break;
      case StatsRange.thisMonth:
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        fromMs = firstDayOfMonth.millisecondsSinceEpoch;
        break;
    }

    final allSessions = await _sessionsDao.getSessionsWithTasksInRange(
      fromMs: fromMs,
      toMs: toMs,
    );
    final completedSessions = allSessions.where((swt) => swt.session.endAt != null).toList();

    if (completedSessions.isEmpty) return null;

    // Czas tej kategorii
    final categorySessions = completedSessions
        .where((swt) => swt.task.categoryId == categoryId)
        .toList();
    final categoryTimeSeconds = categorySessions.fold<int>(
      0,
      (sum, swt) => sum + (swt.session.durationSec as int),
    );

    // Całkowity czas wszystkich kategorii
    final totalTimeSeconds = completedSessions.fold<int>(
      0,
      (sum, swt) => sum + (swt.session.durationSec as int),
    );

    if (totalTimeSeconds == 0) return null;

    // Kategorie z czasem > 0
    final categoriesWithTime = <String>{};
    for (final swt in completedSessions) {
      if (swt.task.categoryId != null) {
        categoriesWithTime.add(swt.task.categoryId!);
      }
    }

    if (categoriesWithTime.isEmpty) return null;

    final averageTimePerCategorySeconds = totalTimeSeconds ~/ categoriesWithTime.length;
    final categorySharePercent = (categoryTimeSeconds / totalTimeSeconds) * 100;

    double differencePercent = 0;
    if (averageTimePerCategorySeconds > 0) {
      differencePercent = ((categoryTimeSeconds - averageTimePerCategorySeconds) /
              averageTimePerCategorySeconds) *
          100;
    }

    return ShareVsAverage(
      categorySharePercent: categorySharePercent,
      averageTimePerCategorySeconds: averageTimePerCategorySeconds,
      differencePercent: differencePercent,
    );
  }

  /// Ranking kategorii (po łącznym czasie).
  Future<List<CategoryRankingEntry>> getCategoryRanking(StatsRange range) async {
    final now = DateTime.now();
    int fromMs;
    int toMs = now.millisecondsSinceEpoch + 1;

    switch (range) {
      case StatsRange.all:
        fromMs = 0;
        break;
      case StatsRange.thisMonth:
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        fromMs = firstDayOfMonth.millisecondsSinceEpoch;
        break;
    }

    final allSessions = await _sessionsDao.getSessionsWithTasksInRange(
      fromMs: fromMs,
      toMs: toMs,
    );
    final completedSessions = allSessions.where((swt) => swt.session.endAt != null).toList();

    // Grupuj po kategoriach
    final categoryTotals = <String, int>{};
    final categoryNames = <String, String>{};

    for (final swt in completedSessions) {
      if (swt.task.categoryId == null) continue;
      final catId = swt.task.categoryId!;
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + (swt.session.durationSec as int);
    }

    // Pobierz nazwy kategorii
    final allCategories = await _categoriesDao.getAll();
    for (final cat in allCategories) {
      categoryNames[cat.id] = cat.name;
    }

    // Sortuj po czasie (desc)
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.asMap().entries.map((entry) {
      final index = entry.key;
      final catEntry = entry.value;
      return CategoryRankingEntry(
        categoryId: catEntry.key,
        categoryName: categoryNames[catEntry.key] ?? 'Nieznana',
        totalTimeSeconds: catEntry.value,
        position: index + 1,
      );
    }).toList();
  }
}

class _PeakHourResult {
  const _PeakHourResult({required this.peakRange, required this.histogram});

  final String? peakRange;
  final List<HourBucket> histogram;
}
