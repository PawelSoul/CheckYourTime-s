import 'package:drift/drift.dart';

import '../app_db.dart';
import '../tables/tasks_table.dart';
import '../tables/sessions_table.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [TasksTable, SessionsTable])
class TasksDao extends DatabaseAccessor<AppDb> with _$TasksDaoMixin {
  TasksDao(super.db);

  // --- CREATE ---
  Future<void> upsertTask(TasksTableCompanion task) async {
    await into(tasksTable).insertOnConflictUpdate(task);
  }

  // --- READ ---
  Future<TaskRow?> getById(String id) async {
    return (select(tasksTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<TaskRow>> getAll({bool includeArchived = false}) async {
    final q = select(tasksTable);
    if (!includeArchived) {
      q.where((t) => t.isArchived.equals(false));
    }
    q.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return q.get();
  }

  Stream<List<TaskRow>> watchAll({bool includeArchived = false}) {
    final q = select(tasksTable);
    if (!includeArchived) {
      q.where((t) => t.isArchived.equals(false));
    }
    q.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return q.watch();
  }

  // --- UPDATE ---
  Future<void> archiveTask(String id, {required bool archived, required int nowMs}) async {
    await (update(tasksTable)..where((t) => t.id.equals(id))).write(
      TasksTableCompanion(
        isArchived: Value(archived),
        updatedAt: Value(nowMs),
      ),
    );
  }

  Future<void> renameTask(String id, {required String name, String? colorHex, required int nowMs}) async {
    await (update(tasksTable)..where((t) => t.id.equals(id))).write(
      TasksTableCompanion(
        name: Value(name),
        colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
        updatedAt: Value(nowMs),
      ),
    );
  }

  // --- DELETE ---
  Future<int> deleteTask(String id) {
    // Uwaga: z FK RESTRICT usunięcie taska z sesjami się nie uda.
    return (delete(tasksTable)..where((t) => t.id.equals(id))).go();
  }
}

/// Alias typów wygodnych do używania w kodzie UI/repo:
typedef TaskRow = TasksTableData;
