import 'package:drift/drift.dart';
import '../app_db.dart';
import '../tables/sessions_table.dart';
import '../tables/tasks_table.dart';

part 'sessions_dao.g.dart';

@DriftAccessor(tables: [SessionsTable, TasksTable])
class SessionsDao extends DatabaseAccessor<AppDb> with _$SessionsDaoMixin {
  SessionsDao(super.db);

  // --- CREATE ---
  Future<void> upsertSession(SessionsTableCompanion session) async {
    await into(sessionsTable).insertOnConflictUpdate(session);
  }

  // Start sesji (endAt = null)
  Future<void> startSession({
    required String sessionId,
    required String taskId,
    String? note,
    required int startAtMs,
    required int nowMs,
  }) async {
    await into(sessionsTable).insert(
      SessionsTableCompanion.insert(
        id: sessionId,
        taskId: taskId,
        startAt: startAtMs,
        endAt: const Value(null),
        durationSec: const Value(0),
        note: note != null ? Value(note) : const Value.absent(),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  // Stop sesji
  Future<void> stopSession({
    required String sessionId,
    required int endAtMs,
    required int nowMs,
  }) async {
    final existing = await (select(sessionsTable)..where((s) => s.id.equals(sessionId))).getSingleOrNull();
    if (existing == null) return;

    final start = existing.startAt;
    final durationSec = ((endAtMs - start) / 1000).round().clamp(0, 1 << 31);

    await (update(sessionsTable)..where((s) => s.id.equals(sessionId))).write(
      SessionsTableCompanion(
        endAt: Value(endAtMs),
        durationSec: Value(durationSec),
        updatedAt: Value(nowMs),
      ),
    );
  }

  // --- READ ---
  Future<SessionRow?> getById(String id) async {
    return (select(sessionsTable)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Aktywna sesja = endAt IS NULL (zakładamy max 1)
  Future<SessionRow?> getActiveSession() async {
    final q = select(sessionsTable)..where((s) => s.endAt.isNull());
    q.orderBy([(s) => OrderingTerm(expression: s.startAt, mode: OrderingMode.desc)]);
    return q.getSingleOrNull();
  }

  Stream<SessionRow?> watchActiveSession() {
    final q = select(sessionsTable)..where((s) => s.endAt.isNull());
    q.orderBy([(s) => OrderingTerm(expression: s.startAt, mode: OrderingMode.desc)]);
    return q.watchSingleOrNull();
  }

  /// Sesje zakończone (endAt != null) w zakresie [fromMs, toMs) po startAt – do kalendarza.
  Future<List<SessionWithTask>> getSessionsWithTasksInRange({
    required int fromMs,
    required int toMs,
  }) async {
    final q = select(sessionsTable).join([
      innerJoin(tasksTable, tasksTable.id.equalsExp(sessionsTable.taskId)),
    ])
      ..where(sessionsTable.startAt.isBiggerOrEqualValue(fromMs) &
          sessionsTable.startAt.isSmallerThanValue(toMs) &
          sessionsTable.endAt.isNotNull())
      ..orderBy([OrderingTerm.desc(sessionsTable.startAt)]);

    final rows = await q.get();
    return rows.map((r) => SessionWithTask(
      session: r.readTable(sessionsTable),
      task: r.readTable(tasksTable),
    )).toList();
  }

  Stream<List<SessionWithTask>> watchSessionsWithTasksInRange({
    required int fromMs,
    required int toMs,
  }) {
    final q = select(sessionsTable).join([
      innerJoin(tasksTable, tasksTable.id.equalsExp(sessionsTable.taskId)),
    ])
      ..where(sessionsTable.startAt.isBiggerOrEqualValue(fromMs) &
          sessionsTable.startAt.isSmallerThanValue(toMs) &
          sessionsTable.endAt.isNotNull())
      ..orderBy([OrderingTerm.desc(sessionsTable.startAt)]);

    return q.watch().map((rows) => rows.map((r) => SessionWithTask(
      session: r.readTable(sessionsTable),
      task: r.readTable(tasksTable),
    )).toList());
  }

  /// Sesje dla konkretnego zadania (zakończone, z notatkami).
  Stream<List<SessionRow>> watchSessionsByTaskId(String taskId) {
    final q = select(sessionsTable)
      ..where((s) => s.taskId.equals(taskId) & s.endAt.isNotNull())
      ..orderBy([(s) => OrderingTerm(expression: s.startAt, mode: OrderingMode.desc)]);
    return q.watch();
  }

  // --- UPDATE ---
  Future<void> updateNote(String sessionId, {String? note, required int nowMs}) async {
    await (update(sessionsTable)..where((s) => s.id.equals(sessionId))).write(
      SessionsTableCompanion(
        note: note != null ? Value(note) : const Value(null),
        updatedAt: Value(nowMs),
      ),
    );
  }

  // --- DELETE ---
  Future<int> deleteSession(String id) {
    return (delete(sessionsTable)..where((s) => s.id.equals(id))).go();
  }

  /// Usuwa wszystkie sesje powiązane z zadaniem (przed usunięciem taska).
  Future<int> deleteSessionsByTaskId(String taskId) {
    return (delete(sessionsTable)..where((s) => s.taskId.equals(taskId))).go();
  }

  /// Usuwa wszystkie sesje z bazy (przed wyczyszczeniem zadań).
  Future<int> deleteAllSessions() {
    return delete(sessionsTable).go();
  }

  /// Zwraca listę taskId zadań, które mają przynajmniej jedną zakończoną sesję w danej kategorii.
  Future<List<String>> getTaskIdsWithCompletedSessionsInCategory(String categoryId) async {
    final q = select(sessionsTable).join([
      innerJoin(tasksTable, tasksTable.id.equalsExp(sessionsTable.taskId)),
    ])
      ..where(
        tasksTable.categoryId.equals(categoryId) &
        sessionsTable.endAt.isNotNull(),
      );
    
    final rows = await q.get();
    final taskIds = rows
        .map((r) => r.readTable(sessionsTable).taskId)
        .toSet()
        .toList();
    return taskIds;
  }

  /// Stream taskId zadań z zakończonymi sesjami w kategorii.
  Stream<List<String>> watchTaskIdsWithCompletedSessionsInCategory(String categoryId) {
    final q = select(sessionsTable).join([
      innerJoin(tasksTable, tasksTable.id.equalsExp(sessionsTable.taskId)),
    ])
      ..where(
        tasksTable.categoryId.equals(categoryId) &
        sessionsTable.endAt.isNotNull(),
      );
    
    return q.watch().map((rows) {
      return rows
          .map((r) => r.readTable(sessionsTable).taskId)
          .toSet()
          .toList();
    });
  }

  /// Stream zadań z zakończonymi sesjami w kategorii (z joinem).
  Stream<List<TasksTableData>> watchTasksWithCompletedSessionsInCategory(String categoryId) {
    final q = select(sessionsTable).join([
      innerJoin(tasksTable, tasksTable.id.equalsExp(sessionsTable.taskId)),
    ])
      ..where(
        tasksTable.categoryId.equals(categoryId) &
        sessionsTable.endAt.isNotNull(),
      )
      ..orderBy([OrderingTerm.desc(tasksTable.createdAt)]);
    
    return q.watch().map((rows) {
      // Zwróć unikalne zadania (po taskId)
      final taskMap = <String, TasksTableData>{};
      for (final row in rows) {
        final task = row.readTable(tasksTable);
        if (!taskMap.containsKey(task.id)) {
          taskMap[task.id] = task;
        }
      }
      // Sortuj po createdAt desc (najnowsze pierwsze)
      final tasks = taskMap.values.toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    });
  }
}

class SessionWithTask {
  final SessionsTableData session;
  final TasksTableData task;
  SessionWithTask({required this.session, required this.task});
}

typedef SessionRow = SessionsTableData;
