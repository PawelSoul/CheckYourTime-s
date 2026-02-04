import 'package:drift/drift.dart';

/// Tabela kategorii (np. Matematyka, Siłownia). Każdy task należy do jednej kategorii.
class CategoriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  TextColumn get colorHex => text().withDefault(const Constant('#4F46E5'))();

  /// Unix epoch ms
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
