import 'package:flutter_riverpod/flutter_riverpod.dart';

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
