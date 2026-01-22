import 'package:drift/drift.dart';

class SessionsTable extends Table {
  TextColumn get id => text()(); // uuid
  TextColumn get taskId => text()();

  /// Unix epoch ms
  IntColumn get startAt => integer()();

  /// Unix epoch ms, null gdy aktywna sesja
  IntColumn get endAt => integer().nullable()();

  /// Zapisana długość w sekundach (opcjonalnie, ale wygodne do statystyk)
  IntColumn get durationSec => integer().withDefault(const Constant(0))();

  TextColumn get note => text().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    // FK do tasks, kasowanie taska blokuje jeśli są sesje (możesz zmienić na CASCADE)
    'FOREIGN KEY(task_id) REFERENCES tasks_table(id) ON DELETE RESTRICT'
  ];
}
