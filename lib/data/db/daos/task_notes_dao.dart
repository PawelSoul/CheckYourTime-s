import 'package:drift/drift.dart';

import '../app_db.dart';
import '../tables/task_notes_table.dart';

part 'task_notes_dao.g.dart';

@DriftAccessor(tables: [TaskNotesTable])
class TaskNotesDao extends DatabaseAccessor<AppDb> with _$TaskNotesDaoMixin {
  TaskNotesDao(super.db);

  Future<void> insertNote({
    required String id,
    required String taskId,
    required String content,
    required int createdAtMs,
  }) async {
    await into(taskNotesTable).insert(
      TaskNotesTableCompanion.insert(
        id: id,
        taskId: taskId,
        content: content,
        createdAtMs: createdAtMs,
      ),
    );
  }

  Stream<List<TaskNotesTableData>> watchNotesByTaskId(String taskId) {
    return (select(taskNotesTable)
          ..where((t) => t.taskId.equals(taskId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)]))
        .watch();
  }
}
