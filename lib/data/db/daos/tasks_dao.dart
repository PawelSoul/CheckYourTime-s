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

  /// Zadania w danej kategorii (tag).
  Future<List<TaskRow>> getByTag(String tag, {bool includeArchived = false}) async {
    final q = select(tasksTable)
      ..where((t) =>
          t.tag.equals(tag) &
          (includeArchived ? t.id.isNotNull() : t.isArchived.equals(false)))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return q.get();
  }

  Stream<List<TaskRow>> watchByTag(String tag, {bool includeArchived = false}) {
    final q = select(tasksTable)
      ..where((t) =>
          t.tag.equals(tag) &
          (includeArchived ? t.id.isNotNull() : t.isArchived.equals(false)))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return q.watch();
  }

  /// Ile zadań w kategorii [tag] ma nazwę zaczynającą się od [namePrefix].
  Future<int> countByTagAndNamePrefix(String tag, String namePrefix) async {
    final rows = await (select(tasksTable)
          ..where((t) => t.tag.equals(tag) & t.name.like('$namePrefix%')))
        .get();
    return rows.length;
  }

  /// Zadania w danej kategorii (po categoryId).
  Future<List<TaskRow>> getByCategoryId(String categoryId, {bool includeArchived = false}) async {
    final q = select(tasksTable)
      ..where((t) =>
          t.categoryId.equals(categoryId) &
          (includeArchived ? t.id.isNotNull() : t.isArchived.equals(false)))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return q.get();
  }

  Stream<List<TaskRow>> watchByCategoryId(String categoryId, {bool includeArchived = false}) {
    final q = select(tasksTable)
      ..where((t) =>
          t.categoryId.equals(categoryId) &
          (includeArchived ? t.id.isNotNull() : t.isArchived.equals(false)))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return q.watch();
  }

  /// Ile zadań w kategorii [categoryId] ma nazwę zaczynającą się od [namePrefix].
  Future<int> countByCategoryIdAndNamePrefix(String categoryId, String namePrefix) async {
    final rows = await (select(tasksTable)
          ..where((t) => t.categoryId.equals(categoryId) & t.name.like('$namePrefix%')))
        .get();
    return rows.length;
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

  /// Ustawia categoryId na null dla wszystkich zadań w danej kategorii (przed usunięciem kategorii).
  Future<void> clearCategoryIdForCategory(String categoryId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await (update(tasksTable)..where((t) => t.categoryId.equals(categoryId))).write(
      TasksTableCompanion(
        categoryId: const Value(null),
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
