import 'package:drift/drift.dart';

import 'categories_table.dart';

class TasksTable extends Table {
  TextColumn get id => text()(); // uuid
  TextColumn get name => text()();
  TextColumn get colorHex => text().withDefault(const Constant('#4F46E5'))();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// v4: kategoria – każdy task należy do jednej kategorii (nullable przy migracji)
  TextColumn get categoryId => text().nullable().references(CategoriesTable, #id)();

  /// v3: tag (zachowany dla kompatybilności, może być null)
  TextColumn get tag => text().nullable()();

  /// v3: planowany czas dzienny/na task (sekundy) - do progressu
  IntColumn get plannedTimeSec => integer().withDefault(const Constant(0))();

  /// v3: cel (sekundy) - np. tygodniowy, zależnie jak interpretujesz w UI
  IntColumn get goalSec => integer().withDefault(const Constant(0))();

  /// Unix epoch ms
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
