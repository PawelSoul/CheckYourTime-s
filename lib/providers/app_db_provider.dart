import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_db.dart';
import '../data/db/daos/categories_dao.dart';
import '../data/db/daos/sessions_dao.dart';
import '../data/db/daos/tasks_dao.dart';
import '../data/db/daos/task_notes_dao.dart';

/// Jedna instancja DB na appkę.
final appDbProvider = Provider<AppDb>((ref) {
  final db = AppDb();
  ref.onDispose(db.close);
  return db;
});

final categoriesDaoProvider = Provider<CategoriesDao>((ref) => ref.watch(appDbProvider).categoriesDao);
final tasksDaoProvider = Provider<TasksDao>((ref) => ref.watch(appDbProvider).tasksDao);
final sessionsDaoProvider = Provider<SessionsDao>((ref) => ref.watch(appDbProvider).sessionsDao);
final taskNotesDaoProvider = Provider<TaskNotesDao>((ref) => ref.watch(appDbProvider).taskNotesDao);
