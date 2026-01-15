import 'package:drift/drift.dart';
import '../app_db.dart';
import '../tables/tasks_table.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDb> with _$TasksDaoMixin {
  TasksDao(AppDb db) : super(db);

  Future<List<Task>> getAllTasks() => select(tasks).get();
  
  Stream<List<Task>> watchAllTasks() => select(tasks).watch();
  
  Future<Task?> getTaskById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }
  
  Future<void> insertTask(TasksCompanion task) => into(tasks).insert(task);
  
  Future<bool> updateTask(TasksCompanion task) => update(tasks).replace(task);
  
  Future<int> deleteTask(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }
  
  Future<int> deleteAllTasks() => delete(tasks).go();
}
