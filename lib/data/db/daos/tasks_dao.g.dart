// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_dao.dart';

// ignore_for_file: type=lint
mixin _$TasksDaoMixin on DatabaseAccessor<AppDb> {
  $CategoriesTableTable get categoriesTable => attachedDatabase.categoriesTable;
  $TasksTableTable get tasksTable => attachedDatabase.tasksTable;
  $SessionsTableTable get sessionsTable => attachedDatabase.sessionsTable;
  TasksDaoManager get managers => TasksDaoManager(this);
}

class TasksDaoManager {
  final _$TasksDaoMixin _db;
  TasksDaoManager(this._db);
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(
          _db.attachedDatabase, _db.categoriesTable);
  $$TasksTableTableTableManager get tasksTable =>
      $$TasksTableTableTableManager(_db.attachedDatabase, _db.tasksTable);
  $$SessionsTableTableTableManager get sessionsTable =>
      $$SessionsTableTableTableManager(_db.attachedDatabase, _db.sessionsTable);
}
