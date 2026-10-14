import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/tasks/data/drift_task_repository.dart';
import 'package:ascend/features/tasks/domain/task.dart';

void main() {
  final created = DateTime(2026, 10, 14, 8);

  late AppDatabase db;
  late DriftTaskRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTaskRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('watchById follows the task and becomes null after deletion', () async {
    await repo.upsert(
      Task(id: 't1', title: 'Write', createdAt: created, updatedAt: created),
    );

    expect((await repo.watchById('t1').first)?.title, 'Write');

    await repo.upsert(
      Task(id: 't1', title: 'Rewrite', createdAt: created, updatedAt: created),
    );
    expect((await repo.watchById('t1').first)?.title, 'Rewrite');

    await repo.delete('t1');
    expect(await repo.watchById('t1').first, isNull);
  });

  test('watchById is null for an unknown id', () async {
    expect(await repo.watchById('ghost').first, isNull);
  });
}