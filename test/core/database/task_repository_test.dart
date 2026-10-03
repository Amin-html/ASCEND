import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/tasks/data/drift_category_repository.dart';
import 'package:ascend/features/tasks/data/drift_task_repository.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

void main() {
  late AppDatabase db;
  late DriftTaskRepository tasks;
  late DriftCategoryRepository categories;

  final created = DateTime(2026, 10, 3, 9);

  Task sample({TaskStatus status = TaskStatus.todo, DateTime? completedAt}) {
    return Task(
      id: 't1',
      title: 'Write spec',
      categoryId: 'cat_work',
      priority: TaskPriority.high,
      status: status,
      dayKey: '2026-10-03',
      xpReward: 30,
      completedAt: completedAt,
      createdAt: created,
      updatedAt: created,
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tasks = DriftTaskRepository(db);
    categories = DriftCategoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('seeds default categories', () async {
    final list = await categories.watchAll().first;
    expect(list.length, 5);
    expect(list.first.name, 'Work');
  });

  test('task roundtrip', () async {
    await tasks.upsert(sample());

    final list = await tasks.watchByDay('2026-10-03').first;
    expect(list.length, 1);
    expect(list.first.title, 'Write spec');
    expect(list.first.priority, TaskPriority.high);
    expect(list.first.xpReward, 30);
  });

  test('upsert updates existing task', () async {
    await tasks.upsert(sample());
    await tasks.upsert(
      sample(
        status: TaskStatus.completed,
        completedAt: DateTime(2026, 10, 3, 12),
      ),
    );

    final task = await tasks.getById('t1');
    expect(task?.status, TaskStatus.completed);
    expect(task?.completedAt, isNotNull);
  });

  test('deleting category clears task category', () async {
    await tasks.upsert(sample());
    await categories.delete('cat_work');

    final task = await tasks.getById('t1');
    expect(task, isNotNull);
    expect(task?.categoryId, isNull);
  });
}