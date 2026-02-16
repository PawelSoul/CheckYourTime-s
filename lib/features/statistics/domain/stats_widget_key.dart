/// Klucze widgetów statystyk (do toggle'ów w ustawieniach).
enum StatsWidgetKey {
  totalTime,
  averageSessionDuration,
  last7DaysChart,
  trend30Days,
  mostProductiveWeekday,
  streak,
  categoryRanking,
  peakHour,
  shareVsAverage,
}

extension StatsWidgetKeyX on StatsWidgetKey {
  String get displayName {
    switch (this) {
      case StatsWidgetKey.totalTime:
        return 'Łączny czas';
      case StatsWidgetKey.averageSessionDuration:
        return 'Średnia długość sesji';
      case StatsWidgetKey.last7DaysChart:
        return 'Wykres ostatnich 7 dni';
      case StatsWidgetKey.trend30Days:
        return 'Trend 30 dni';
      case StatsWidgetKey.mostProductiveWeekday:
        return 'Najbardziej produktywny dzień';
      case StatsWidgetKey.streak:
        return 'Streak';
      case StatsWidgetKey.categoryRanking:
        return 'Ranking kategorii';
      case StatsWidgetKey.peakHour:
        return 'Najczęstsza godzina pracy';
      case StatsWidgetKey.shareVsAverage:
        return 'Porównanie do średniej';
    }
  }
}
