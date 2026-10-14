import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/tasks/data/drift_task_repository.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

void main() {
  final created = DateTime(2026, 10, 1);

  late AppDatabase db;
  late DriftTaskRepository repo;

  Future<void> add(
      String id, {
        String? dayKey,
        TaskStatus status = TaskStatus.todo,
        DateTime? start,
      }) {
    return repo.upsert(
      Task(
        id: id,
        title: 'Task $id',
        dayKey: dayKey,
        startAt: start,
        status: status,
        createdAt: created,
        updatedAt: created,
      ),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTaskRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('returns open tasks inside the range, ordered by day and time', () async {
    await add('a', dayKey: '2026-10-13', start: DateTime(2026, 10, 13, 18));
    await add(
      'b',
      dayKey: '2026-10-13',
      status: TaskStatus.inProgress,
      start: DateTime(2026, 10, 13, 9),
    );
    await add('c', dayKey: '2026-10-13', status: TaskStatus.completed);
    await add('d', dayKey: '2026-10-14', status: TaskStatus.cancelled);
    await add('e', dayKey: '2026-10-15');
    await add('f');
    await add('g', dayKey: '2026-10-30');

    final result = await repo.watchOpenInRange('2026-10-13', '2026-10-20').first;

    expect(result.map((t) => t.id), ['b', 'a', 'e']);
  });

  test('both ends of the range are included', () async {
    await add('a', dayKey: '2026-10-13');
    await add('b', dayKey: '2026-10-20');
    await add('c', dayKey: '2026-10-21');

    final result = await repo.watchOpenInRange('2026-10-13', '2026-10-20').first;

    expect(result.map((t) => t.id).toSet(), {'a', 'b'});
  });

  test('an empty range gives an empty list', () async {
    expect(await repo.watchOpenInRange('2026-10-13', '2026-10-20').first, isEmpty);
  });
}