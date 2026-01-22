import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/tasks_table.dart';
import 'tables/sessions_table.dart';
import 'daos/tasks_dao.dart';
import 'daos/sessions_dao.dart';

part 'app_db.g.dart';

@DriftDatabase(
  tables: [
    TasksTable,
    SessionsTable,
  ],
  daos: [
    TasksDao,
    SessionsDao,
  ],
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  /// Zwiększaj przy każdej zmianie schematu.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();

      // Dla SQLite trzeba włączyć FK:
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, to) async {
      await customStatement('PRAGMA foreign_keys = ON');

      // Przykład migracji v1 -> v2:
      if (from < 2) {
        // Załóżmy, że w v2 dodaliśmy kolumnę "note" w sessions.
        // Jeśli już ją masz, usuń ten blok.
        await m.addColumn(sessionsTable, sessionsTable.note);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Drift Flutter: najlepiej użyć driftDatabase(...) albo LazyDatabase.
/// Poniżej klasyczne LazyDatabase.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'checkyourtime.sqlite'));
    return NativeDatabase(file);
  });
}
