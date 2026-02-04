// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionsDaoMixin on DatabaseAccessor<AppDb> {
  $SessionsTableTable get sessionsTable => attachedDatabase.sessionsTable;
  $CategoriesTableTable get categoriesTable => attachedDatabase.categoriesTable;
  $TasksTableTable get tasksTable => attachedDatabase.tasksTable;
  SessionsDaoManager get managers => SessionsDaoManager(this);
}

class SessionsDaoManager {
  final _$SessionsDaoMixin _db;
  SessionsDaoManager(this._db);
  $$SessionsTableTableTableManager get sessionsTable =>
      $$SessionsTableTableTableManager(_db.attachedDatabase, _db.sessionsTable);
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(
          _db.attachedDatabase, _db.categoriesTable);
  $$TasksTableTableTableManager get tasksTable =>
      $$TasksTableTableTableManager(_db.attachedDatabase, _db.tasksTable);
}
