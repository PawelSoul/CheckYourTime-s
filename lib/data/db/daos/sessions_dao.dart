import 'package:drift/drift.dart';
import '../app_db.dart';
import '../tables/sessions_table.dart';

part 'sessions_dao.g.dart';

@DriftAccessor(tables: [Sessions])
class SessionsDao extends DatabaseAccessor<AppDb> with _$SessionsDaoMixin {
  SessionsDao(AppDb db) : super(db);

  Future<List<Session>> getAllSessions() => select(sessions).get();
  
  Stream<List<Session>> watchAllSessions() => select(sessions).watch();
  
  Future<Session?> getSessionById(String id) {
    return (select(sessions)..where((s) => s.id.equals(id))).getSingleOrNull();
  }
  
  Future<List<Session>> getSessionsByTaskName(String taskName) {
    return (select(sessions)..where((s) => s.taskName.equals(taskName))).get();
  }
  
  Future<List<Session>> getSessionsByDateRange(DateTime start, DateTime end) {
    return (select(sessions)
      ..where((s) => s.startedAt.isBiggerOrEqualValue(start))
      ..where((s) => s.startedAt.isSmallerOrEqualValue(end))
      ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .get();
  }
  
  Future<void> insertSession(SessionsCompanion session) => 
      into(sessions).insert(session);
  
  Future<bool> updateSession(SessionsCompanion session) => 
      update(sessions).replace(session);
  
  Future<int> deleteSession(String id) {
    return (delete(sessions)..where((s) => s.id.equals(id))).go();
  }
  
  Future<int> deleteAllSessions() => delete(sessions).go();
}
