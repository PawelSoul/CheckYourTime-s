import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/daos/tasks_dao.dart';
import '../../../providers/app_db_provider.dart';
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

/// Lista nazw kategorii (unikalne tagi z zadań), posortowana.
final categoriesStreamProvider = StreamProvider<List<String>>((ref) {
  final stream = ref.watch(tasksStreamProvider);
  return stream.when(
    data: (tasks) {
      final tags = tasks
          .map((t) => t.tag)
          .where((tag) => tag != null && tag.trim().isNotEmpty)
          .map((e) => e!.trim())
          .toSet()
          .toList()
        ..sort();
      return Stream.value(tags);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Stream zadań dla danej kategorii (po tagu).
final tasksByCategoryProvider =
    StreamProvider.autoDispose.family<List<TaskRow>, String>((ref, categoryTag) {
  final dao = ref.watch(tasksDaoProvider);
  return dao.watchByTag(categoryTag);
});
