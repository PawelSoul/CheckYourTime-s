import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/daos/categories_dao.dart';
import '../../../data/db/daos/sessions_dao.dart';
import '../../../data/db/daos/tasks_dao.dart';
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
