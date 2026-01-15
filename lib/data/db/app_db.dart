import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/tasks_table.dart';
import 'tables/sessions_table.dart';
import 'daos/tasks_dao.dart';
import 'daos/sessions_dao.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [Tasks, Sessions], daos: [TasksDao, SessionsDao])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle migrations here when schema version changes
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'checkyourtime.db'));
    return NativeDatabase(file);
  });
}
