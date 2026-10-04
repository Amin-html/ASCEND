import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/core/services/clock.dart';
import 'package:ascend/core/services/id_generator.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';
import 'package:ascend/features/tasks/data/drift_task_actions.dart';
import 'package:ascend/features/tasks/data/drift_task_repository.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

class FakeClock implements Clock {
  FakeClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

class SequentialIds implements IdGenerator {
  int _n = 0;

  @override
  String newId() => 'id_${_n++}';
}

void main() {
  const today = '2026-10-03';
  final morning = DateTime(2026, 10, 3, 10);

  late AppDatabase db;
  late FakeClock clock;
  late DriftTaskActions actions;
  late DriftTaskRepository repo;

  Task makeTask(String id, {String? dayKey, int xp = 10}) {
    return Task(
      id: id,
      title: 'Task $id',
      dayKey: dayKey,
      xpReward: xp,
      createdAt: morning,
      updatedAt: morning,
    );
  }

  Future<int> totalXp() async {
    final events = await db.select(db.xpEvents).get();
    return events.fold<int>(0, (sum, e) => sum + e.amount);
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clock = FakeClock(morning);
    actions = DriftTaskActions(
      db: db,
      clock: clock,
      ids: SequentialIds(),
      engine: const XpEngine(),
    );
    repo = DriftTaskRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('complete awards task XP and marks the task completed', () async {
    await actions.save(makeTask('a', xp: 25));

    final result = await actions.complete('a');

    expect(result, isNotNull);
    expect(result!.xpGained, 25);
    expect(result.bonusXp, 0);
    expect(await totalXp(), 25);

    final task = await repo.getById('a');
    expect(task?.status, TaskStatus.completed);
    expect(task?.completedAt, isNotNull);
  });

  test('complete is idempotent', () async {
    await actions.save(makeTask('a', xp: 25));

    await actions.complete('a');
    final second = await actions.complete('a');

    expect(second, isNull);
    expect(await totalXp(), 25);
  });

  test('complete on unknown task returns null', () async {
    expect(await actions.complete('missing'), isNull);
  });

  test('reopen takes the XP back', () async {
    await actions.save(makeTask('a', xp: 25));
    await actions.complete('a');

    await actions.reopen('a');

    expect(await totalXp(), 0);
    final task = await repo.getById('a');
    expect(task?.status, TaskStatus.todo);
    expect(task?.completedAt, isNull);
  });

  test('task can be completed again after reopen', () async {
    await actions.save(makeTask('a', xp: 25));
    await actions.complete('a');
    await actions.reopen('a');

    final result = await actions.complete('a');

    expect(result?.xpGained, 25);
    expect(await totalXp(), 25);
  });

  test('daily plan bonus when every planned task of today is done', () async {
    await actions.save(makeTask('a', dayKey: today));
    await actions.save(makeTask('b', dayKey: today));

    final first = await actions.complete('a');
    expect(first!.xpGained, 10);

    final second = await actions.complete('b');
    expect(second!.xpGained, 30);
    expect(second.bonusXp, 20);
    expect(await totalXp(), 40);
  });

  test('reopen removes the daily plan bonus', () async {
    await actions.save(makeTask('a', dayKey: today));
    await actions.complete('a');
    expect(await totalXp(), 30);

    await actions.reopen('a');

    expect(await totalXp(), 0);
  });

  test('streak bonus on the third consecutive day', () async {
    await actions.save(makeTask('d1'));
    await actions.save(makeTask('d2'));
    await actions.save(makeTask('d3'));

    clock.current = DateTime(2026, 10, 1, 10);
    final r1 = await actions.complete('d1');
    clock.current = DateTime(2026, 10, 2, 10);
    final r2 = await actions.complete('d2');
    clock.current = DateTime(2026, 10, 3, 10);
    final r3 = await actions.complete('d3');

    expect(r1!.bonusXp, 0);
    expect(r2!.bonusXp, 0);
    expect(r3!.streakDays, 3);
    expect(r3.bonusXp, 10);
    expect(await totalXp(), 40);
  });

  test('level up is reported', () async {
    await actions.save(makeTask('big', xp: 120));

    final result = await actions.complete('big');

    expect(result!.levelBefore, 1);
    expect(result.levelAfter, 2);
    expect(result.leveledUp, isTrue);
    expect(result.totalXpAfter, 120);
  });

  test('delete removes a completed task together with its XP', () async {
    await actions.save(makeTask('a', xp: 25));
    await actions.complete('a');

    await actions.delete('a');

    expect(await totalXp(), 0);
    expect(await repo.getById('a'), isNull);
  });

  test('daily stats follow saves and completions', () async {
    await actions.save(makeTask('a', dayKey: today));
    await actions.save(makeTask('b', dayKey: today));

    var stats = await (db.select(db.dailyStats)
      ..where((s) => s.dayKey.equals(today)))
        .getSingle();
    expect(stats.tasksPlanned, 2);
    expect(stats.tasksCompleted, 0);
    expect(stats.planCompleted, isFalse);

    await actions.complete('a');

    stats = await (db.select(db.dailyStats)
      ..where((s) => s.dayKey.equals(today)))
        .getSingle();
    expect(stats.tasksCompleted, 1);
    expect(stats.xpEarned, 10);
    expect(stats.planCompleted, isFalse);
  });
}