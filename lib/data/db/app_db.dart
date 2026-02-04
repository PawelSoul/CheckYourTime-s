import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/tasks_table.dart';
import 'tables/sessions_table.dart';

import 'daos/tasks_dao.dart';
import 'daos/sessions_dao.dart';

part 'app_db.g.dart';

@DriftDatabase(
  tables: [TasksTable, SessionsTable],
  daos: [TasksDao, SessionsDao],
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  /// v1 -> v2 -> v3
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, to) async {
      await customStatement('PRAGMA foreign_keys = ON');

      // v2: dodaliśmy sessions.note
      if (from < 2) {
        await m.addColumn(sessionsTable, sessionsTable.note);
      }

      // v3: dodaliśmy tasks.tag / plannedTimeSec / goalSec
      if (from < 3) {
        await m.addColumn(tasksTable, tasksTable.tag);
        await m.addColumn(tasksTable, tasksTable.plannedTimeSec);
        await m.addColumn(tasksTable, tasksTable.goalSec);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'checkyourtime.sqlite'));
    return NativeDatabase(file);
  });
}
