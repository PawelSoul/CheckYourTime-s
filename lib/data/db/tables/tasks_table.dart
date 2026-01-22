import 'package:drift/drift.dart';

class TasksTable extends Table {
  TextColumn get id => text()(); // np. uuid
  TextColumn get name => text()();
  TextColumn get colorHex => text().withDefault(const Constant('#4F46E5'))();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Unix epoch ms
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
