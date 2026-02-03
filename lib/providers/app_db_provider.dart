import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_db.dart';
import '../data/db/daos/sessions_dao.dart';
import '../data/db/daos/tasks_dao.dart';

/// Jedna instancja DB na appkę.
/// AutoDispose? Nie — DB zwykle ma żyć cały czas.
/// Tu używam Provider + onDispose, żeby było "czysto".
final appDbProvider = Provider<AppDb>((ref) {
  final db = AppDb();
  ref.onDispose(db.close);
  return db;
});

final tasksDaoProvider = Provider<TasksDao>((ref) => ref.watch(appDbProvider).tasksDao);
final sessionsDaoProvider = Provider<SessionsDao>((ref) => ref.watch(appDbProvider).sessionsDao);
