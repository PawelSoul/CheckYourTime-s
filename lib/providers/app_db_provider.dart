import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db/app_db.dart';

/// Jedna instancja DB na appkę.
/// AutoDispose? Nie — DB zwykle ma żyć cały czas.
/// Tu używam Provider + onDispose, żeby było "czysto".
final appDbProvider = Provider<AppDb>((ref) {
  final db = AppDb();
  ref.onDispose(() => db.close());
  return db;
});

final tasksDaoProvider = Provider((ref) => ref.watch(appDbProvider).tasksDao);
final sessionsDaoProvider = Provider((ref) => ref.watch(appDbProvider).sessionsDao);
