import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/daos/categories_dao.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../providers/app_db_provider.dart';
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
  return sessionsDao.watchTasksWithCompletedSessionsInCategory(categoryId);
});

/// Wybrana kategoria (do pokazania tasków po prawej).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Filtr czasowy listy zadań (wszystkie, dzisiaj, ostatnie 7/30 dni, miesiąc, rok).
final tasksDateFilterProvider =
    StateProvider<TasksDateFilterState>((ref) => TasksDateFilterState.all);
