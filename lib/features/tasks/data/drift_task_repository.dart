import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/tasks/data/task_mappers.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_repository.dart';

class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Task>> watchByDay(String dayKey) {
    final query = _db.select(_db.tasks)
      ..where((t) => t.dayKey.equals(dayKey))
      ..orderBy([
            (t) => OrderingTerm.asc(t.status),
            (t) => OrderingTerm.desc(t.priority),
            (t) => OrderingTerm.asc(t.startAt),
            (t) => OrderingTerm.asc(t.createdAt),
      ]);
    return query.watch().map((rows) => rows.map(taskFromRow).toList());
  }

  @override
  Stream<List<Task>> watchAll() {
    final query = _db.select(_db.tasks)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(taskFromRow).toList());
  }

  @override
  Future<Task?> getById(String id) async {
    final row = await (_db.select(_db.tasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : taskFromRow(row);
  }

  @override
  Future<void> upsert(Task task) async {
    await _db.into(_db.tasks).insertOnConflictUpdate(taskToCompanion(task));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }
}