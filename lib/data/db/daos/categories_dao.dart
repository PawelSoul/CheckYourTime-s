import 'package:drift/drift.dart';

import '../app_db.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoriesDao extends DatabaseAccessor<AppDb> with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<void> insertCategory(CategoriesTableCompanion category) async {
    await into(categoriesTable).insert(category);
  }

  Future<void> upsertCategory(CategoriesTableCompanion category) async {
    await into(categoriesTable).insertOnConflictUpdate(category);
  }

  Future<CategoryRow?> getById(String id) async {
    return (select(categoriesTable)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  Future<List<CategoryRow>> getAll() async {
    return (select(categoriesTable)
          ..orderBy([(c) => OrderingTerm(expression: c.name, mode: OrderingMode.asc)]))
        .get();
  }

  Stream<List<CategoryRow>> watchAll() {
    return (select(categoriesTable)
          ..orderBy([(c) => OrderingTerm(expression: c.name, mode: OrderingMode.asc)]))
        .watch();
  }
}

typedef CategoryRow = CategoriesTableData;
