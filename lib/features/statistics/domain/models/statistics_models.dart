/// Modele DTO dla statystyk kategorii.

/// Zakres czasowy dla statystyk.
enum StatsRange {
  all,
  thisMonth,
}

/// Wiadro danych dla jednego dnia (do wykresów).
class DayBucket {
  const DayBucket({
    required this.date,
    required this.totalMinutes,
    required this.sessionCount,
  });

  final DateTime date;
  final int totalMinutes; // suma minut w tym dniu
  final int sessionCount; // liczba sesji w tym dniu
}

/// Wiadro danych dla jednej godziny (0-23).
class HourBucket {
  const HourBucket({
    required this.hour,
    required this.sessionCount,
  });

  final int hour; // 0-23
  final int sessionCount; // liczba sesji w tej godzinie
}

/// Statystyki kategorii.
class CategoryStats {
  const CategoryStats({
    required this.categoryId,
    required this.totalTimeSeconds,
    required this.averageSessionDurationSeconds,
    required this.last7Days,
    required this.trend30Days,
    required this.mostProductiveWeekday,
    required this.streak,
    required this.peakHourRange,
    required this.hourHistogram,
    required this.shareVsAverage,
  });

  final String categoryId;
  final int totalTimeSeconds; // łączny czas w sekundach
  final double averageSessionDurationSeconds; // średnia długość sesji
  final List<DayBucket> last7Days; // ostatnie 7 dni (0-6, najstarszy-najnowszy)
  final TrendData? trend30Days; // trend ostatnich 30 dni
  final int? mostProductiveWeekday; // 1=Mon, 7=Sun
  final int streak; // streak dni
  final String? peakHourRange; // np. "21:00-22:00"
  final List<HourBucket> hourHistogram; // histogram godzin 0-23
  final ShareVsAverage? shareVsAverage; // udział vs średnia
}

/// Dane trendu (ostatnie 30 dni vs poprzednie 30 dni).
class TrendData {
  const TrendData({
    required this.current30Days,
    required this.previous30Days,
  });

  final List<DayBucket> current30Days; // ostatnie 30 dni
  final List<DayBucket> previous30Days; // poprzednie 30 dni (przed ostatnimi 30)

  /// Procentowa zmiana trendu (null jeśli brak danych poprzednich).
  double? get trendPercentage {
    if (previous30Days.isEmpty) return null;
    final currentTotal = current30Days.fold<int>(
      0,
      (sum, day) => sum + day.totalMinutes,
    );
    final previousTotal = previous30Days.fold<int>(
      0,
      (sum, day) => sum + day.totalMinutes,
    );
    if (previousTotal == 0) return null;
    return ((currentTotal - previousTotal) / previousTotal * 100);
  }
}

/// Udział kategorii vs średnia wszystkich kategorii.
class ShareVsAverage {
  const ShareVsAverage({
    required this.categorySharePercent,
    required this.averageTimePerCategorySeconds,
    required this.differencePercent,
  });

  final double categorySharePercent; // udział tej kategorii w całkowitym czasie (%)
  final int averageTimePerCategorySeconds; // średni czas na kategorię
  final double differencePercent; // różnica vs średnia (+/- %)
}

/// Pozycja kategorii w rankingu.
class CategoryRankingEntry {
  const CategoryRankingEntry({
    required this.categoryId,
    required this.categoryName,
    required this.totalTimeSeconds,
    required this.position,
  });

  final String categoryId;
  final String categoryName;
  final int totalTimeSeconds;
  final int position; // pozycja w rankingu (1-based)
}
