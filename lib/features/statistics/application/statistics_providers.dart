import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/daos/categories_dao.dart';
import '../../../data/db/daos/sessions_dao.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../features/tasks/application/tasks_date_filter.dart';
import '../../../providers/app_db_provider.dart';
import '../domain/models/statistics_models.dart';
import 'statistics_service.dart';

final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService(
    sessionsDao: ref.watch(sessionsDaoProvider),
    tasksDao: ref.watch(tasksDaoProvider),
    categoriesDao: ref.watch(categoriesDaoProvider),
  );
});

/// Provider łącznego czasu (sekundy) kategorii w wybranym okresie listy zadań.
final categorySummaryTotalSecondsProvider =
    FutureProvider.family<int, CategorySummaryParams>((ref, params) async {
  final service = ref.watch(statisticsServiceProvider);
  final range = params.filterState.timeRangeMs;
  return service.getCategoryTotalTimeInRange(
    params.categoryId,
    range.fromMs,
    range.toMs,
  );
});

class CategorySummaryParams {
  const CategorySummaryParams({
    required this.categoryId,
    required this.filterState,
  });

  final String categoryId;
  final TasksDateFilterState filterState;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorySummaryParams &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          filterState.kind == other.filterState.kind &&
          filterState.year == other.filterState.year &&
          filterState.month == other.filterState.month;

  @override
  int get hashCode => Object.hash(categoryId, filterState.kind, filterState.year, filterState.month);
}

/// Provider dla statystyk kategorii (cache'owany per categoryId + range).
final categoryStatsProvider =
    FutureProvider.family<CategoryStats?, CategoryStatsParams>((ref, params) async {
  final service = ref.watch(statisticsServiceProvider);
  return service.getCategoryStats(params.categoryId, params.range);
});

class CategoryStatsParams {
  const CategoryStatsParams({
    required this.categoryId,
    required this.range,
  });

  final String categoryId;
  final StatsRange range;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryStatsParams &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          range == other.range;

  @override
  int get hashCode => categoryId.hashCode ^ range.hashCode;
}

/// Provider dla rankingu kategorii.
final categoryRankingProvider =
    FutureProvider.family<List<CategoryRankingEntry>, StatsRange>((ref, range) async {
  final service = ref.watch(statisticsServiceProvider);
  return service.getCategoryRanking(range);
});
