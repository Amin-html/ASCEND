import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/tasks/data/task_mappers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/category_repository.dart';

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Category>> watchAll() {
    final query = _db.select(_db.categories)
      ..orderBy([
            (c) => OrderingTerm.asc(c.sortOrder),
            (c) => OrderingTerm.asc(c.name),
      ]);
    return query.watch().map((rows) => rows.map(categoryFromRow).toList());
  }

  @override
  Future<void> upsert(Category category) async {
    final now = DateTime.now();
    await _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        id: category.id,
        name: category.name,
        colorValue: category.colorValue,
        iconKey: category.iconKey,
        isDefault: Value(category.isDefault),
        sortOrder: Value(category.sortOrder),
        createdAt: now,
        updatedAt: now,
      ),
      onConflict: DoUpdate(
            (old) => CategoriesCompanion(
          name: Value(category.name),
          colorValue: Value(category.colorValue),
          iconKey: Value(category.iconKey),
          sortOrder: Value(category.sortOrder),
          updatedAt: Value(now),
        ),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }
}