/// Wyjaśnienia dla każdej statystyki.
class StatsExplanations {
  StatsExplanations._();

  static const Map<String, String> explanations = {
    'totalTime': 'Suma czasu spędzonego we wszystkich ukończonych sesjach w tej kategorii w wybranym zakresie czasowym.',
    'averageSessionDuration': 'Średnia długość pojedynczej sesji w tej kategorii. Obliczana jako suma czasu podzielona przez liczbę ukończonych sesji.',
    'shareVsAverage': 'Pokazuje udział tej kategorii w całkowitym czasie wszystkich kategorii oraz różnicę względem średniego czasu na kategorię.',
    'mostProductiveWeekday': 'Dzień tygodnia, w którym spędzono najwięcej czasu w tej kategorii w wybranym zakresie.',
    'streak': 'Liczba kolejnych dni z rzędu, w których wykonano minimum 2 sesje i spędzono co najmniej 10 minut w tej kategorii.',
    'peakHour': 'Godzina (lub zakres godzin), w której wykonano najwięcej sesji w tej kategorii. Histogram pokazuje rozkład aktywności w ciągu doby.',
    'categoryRanking': 'Ranking wszystkich kategorii posortowany po łącznym czasie spędzonym w ukończonych sesjach. Twoja aktualna kategoria jest wyróżniona.',
    'last7DaysChart': 'Wykres pokazuje sumę minut spędzonych w tej kategorii każdego dnia w ostatnich 7 dniach.',
    'trend30Days': 'Wykres pokazuje trend aktywności w ostatnich 30 dniach. Wskaźnik procentowy porównuje ostatnie 30 dni z poprzednimi 30 dniami.',
  };

  static String? get(String key) => explanations[key];
}
