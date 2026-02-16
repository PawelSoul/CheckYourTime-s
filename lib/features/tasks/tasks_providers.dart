import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/daos/categories_dao.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../providers/app_db_provider.dart';
import '../statistics/application/statistics_providers.dart';
import '../statistics/domain/models/statistics_models.dart';
import 'application/tasks_date_filter.dart';
import 'data/tasks_repository.dart';
import 'data/tasks_repository_impl.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final db = ref.watch(appDbProvider);
  return TasksRepositoryImpl(db.tasksDao);
});

final tasksStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(tasksRepositoryProvider);
  return repo.watchAll();
});

/// Lista kategorii z tabeli categories.
final categoriesStreamProvider = StreamProvider<List<CategoryRow>>((ref) {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.watchAll();
});

/// Lista kategorii posortowana od najczęściej używanej do najmniej (wg łącznego czasu sesji).
final categoriesSortedByUsageProvider = Provider<AsyncValue<List<CategoryRow>>>((ref) {
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  final rankingAsync = ref.watch(categoryRankingProvider(StatsRange.all));

  return categoriesAsync.when(
    data: (categories) {
      return rankingAsync.when(
        data: (ranking) => AsyncData(_sortCategoriesByRanking(categories, ranking)),
        loading: () => AsyncData(categories),
        error: (_, __) => AsyncData(categories),
      );
    },
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
  );
});

List<CategoryRow> _sortCategoriesByRanking(
  List<CategoryRow> categories,
  List<CategoryRankingEntry> ranking,
) {
  final byId = {for (final c in categories) c.id: c};
  final result = <CategoryRow>[];
  for (final entry in ranking) {
    final cat = byId[entry.categoryId];
    if (cat != null) {
      result.add(cat);
      byId.remove(entry.categoryId);
    }
  }
  result.addAll(byId.values);
  return result;
}

/// Kategoria po id (z aktualnej listy). Używane do koloru przy zadaniach.
final categoryByIdProvider =
    Provider.family<CategoryRow?, String>((ref, categoryId) {
  final categories = ref.watch(categoriesStreamProvider).valueOrNull;
  if (categories == null) return null;
  try {
    return categories.firstWhere((c) => c.id == categoryId);
  } catch (_) {
    return null;
  }
});

/// Stream zadań dla danej kategorii (po categoryId) - tylko zadania z zakończonymi sesjami.
final tasksByCategoryProvider =
    StreamProvider.autoDispose.family<List<TaskRow>, String>((ref, categoryId) {
  final sessionsDao = ref.watch(sessionsDaoProvider);
  
  // Użyj bezpośrednio metody z joinem, która zwraca zadania z zakończonymi sesjami
  // TasksTableData jest tym samym co TaskRow (dzięki typedef w tasks_dao.dart)
  return sessionsDao.watchTasksWithCompletedSessionsInCategory(categoryId)
      .map((tasks) => List<TaskRow>.from(tasks));
});

/// Wybrana kategoria (do pokazania tasków po prawej).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Filtr czasowy listy zadań (wszystkie, dzisiaj, ostatnie 7/30 dni, miesiąc, rok).
final tasksDateFilterProvider =
    StateProvider<TasksDateFilterState>((ref) => TasksDateFilterState.all);
