import '../../../data/db/daos/sessions_dao.dart';
import '../../../data/db/daos/tasks_dao.dart';
import '../../../data/db/app_db.dart';


class DriftSessionsRepository implements SessionsRepository {
  DriftSessionsRepository({
    required SessionsDao sessionsDao,
    required TasksDao tasksDao,
  })  : _sessionsDao = sessionsDao,
        _tasksDao = tasksDao;

  final SessionsDao _sessionsDao;
  final TasksDao _tasksDao;

  @override
  Stream<List<CompletedSession>> watchAll() {
    // Zakładam, że chcesz listę sesji z nazwą taska.
    // To robimy joinem w DAO (najczyściej), ale tu zrobimy bezpośrednio na DB przez dao.db.
    final db = _sessionsDao.attachedDatabase;

    final q = db.select(db.sessionsTable).join([
      innerJoin(db.tasksTable, db.tasksTable.id.equalsExp(db.sessionsTable.taskId)),
    ])
      ..where(db.sessionsTable.endAt.isNotNull())
      ..orderBy([OrderingTerm.desc(db.sessionsTable.startAt)]);

    return q.watch().map((rows) {
      return rows.map((r) {
        final s = r.readTable(db.sessionsTable);
        final t = r.readTable(db.tasksTable);

        return CompletedSession(
          id: s.id,
          taskId: t.id,
          taskName: t.name,
          startedAt: DateTime.fromMillisecondsSinceEpoch(s.startAt),
          endedAt: DateTime.fromMillisecondsSinceEpoch(s.endAt!),
          duration: Duration(seconds: s.durationSec),
        );
      }).toList();
    });
  }

  @override
  Future<void> add(CompletedSession s) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _sessionsDao.upsertSession(
      SessionsTableCompanion.insert(
        id: s.id,
        taskId: s.taskId,
        startAt: s.startedAt.millisecondsSinceEpoch,
        endAt: Value(s.endedAt.millisecondsSinceEpoch),
        durationSec: Value(s.duration.inSeconds),
        note: const Value.absent(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
