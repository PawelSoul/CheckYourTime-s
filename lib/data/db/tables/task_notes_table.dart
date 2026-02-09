import 'package:drift/drift.dart';

/// Notatki powiązane z zadaniem (wiele notatek na jedno zadanie).
class TaskNotesTable extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();

  TextColumn get content => text()();

  /// Unix epoch ms
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY(task_id) REFERENCES tasks_table(id) ON DELETE CASCADE'
      ];
}
