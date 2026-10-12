import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/focus/data/drift_focus_actions.dart';
import 'package:ascend/features/focus/data/drift_focus_repository.dart';
import 'package:ascend/features/focus/domain/focus_models.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';

import '../../helpers/fakes.dart';

void main() {
  const today = '2026-10-06';
  final now = DateTime(2026, 10, 6, 14, 30);

  late AppDatabase db;
  late DriftFocusActions actions;
  late DriftFocusRepository repo;

  FocusSessionInput session(
      int seconds, {
        String? taskId,
        FocusMode mode = FocusMode.countdown,
        int? planned,
      }) {
    return FocusSessionInput(
      mode: mode,
      plannedSeconds: planned,
      actualSeconds: seconds,
      startedAt: now.subtract(Duration(seconds: seconds)),
      taskId: taskId,
    );
  }

  Future<int> totalXp() async {
    final events = await db.select(db.xpEvents).get();
    return events.fold<int>(0, (sum, e) => sum + e.amount);
  }

  Future<void> addTask(String id, String title) {
    return db.into(db.tasks).insert(
      TasksCompanion.insert(
        id: id,
        title: title,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<TaskRow> taskRow(String id) =>
      (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    actions = DriftFocusActions(
      db: db,
      clock: FakeClock(now),
      ids: SequentialIds(),
      engine: const XpEngine(),
    );
    repo = DriftFocusRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('a session under a minute is not saved', () async {
    final result = await actions.complete(session(59));

    expect(result, isNull);
    expect(await db.select(db.focusSessions).get(), isEmpty);
    expect(await totalXp(), 0);
  });

  test('25 minutes gives 5 XP and is recorded', () async {
    final result = await actions.complete(session(1500, planned: 1500));

    expect(result, isNotNull);
    expect(result!.xpGained, 5);
    expect(await totalXp(), 5);

    final row = (await db.select(db.focusSessions).get()).single;
    expect(row.actualSeconds, 1500);
    expect(row.plannedSeconds, 1500);
    expect(row.xpAwarded, 5);
    expect(row.dayKey, today);
    expect(row.mode, FocusMode.countdown.index);
    expect(row.endedAt, isNotNull);
  });

  test('XP is capped per session', () async {
    final result = await actions.complete(session(3 * 3600));

    expect(result!.xpGained, 20);
  });

  test('a short but valid session is saved without XP', () async {
    final result = await actions.complete(session(240));

    expect(result, isNotNull);
    expect(result!.xpGained, 0);
    expect(await db.select(db.xpEvents).get(), isEmpty);
    expect((await db.select(db.focusSessions).get()).length, 1);
  });

  test('stopwatch mode is stored', () async {
    await actions.complete(session(600, mode: FocusMode.stopwatch));

    final row = (await db.select(db.focusSessions).get()).single;
    expect(row.mode, FocusMode.stopwatch.index);
    expect(row.plannedSeconds, isNull);
  });

  test('daily stats track focus seconds and XP', () async {
    await actions.complete(session(1500));
    await actions.complete(session(600));

    final stats = await (db.select(db.dailyStats)
      ..where((s) => s.dayKey.equals(today)))
        .getSingle();
    expect(stats.focusSeconds, 2100);
    expect(stats.xpEarned, 7);
  });

  test('time is added to the linked task', () async {
    await addTask('t1', 'Write report');

    await actions.complete(session(1500, taskId: 't1'));
    expect((await taskRow('t1')).actualMinutes, 25);

    await actions.complete(session(600, taskId: 't1'));
    expect((await taskRow('t1')).actualMinutes, 35);
  });

  test('a task that no longer exists is ignored', () async {
    await actions.complete(session(1500, taskId: 'ghost'));

    final row = (await db.select(db.focusSessions).get()).single;
    expect(row.taskId, isNull);
  });

  test('a level up is reported', () async {
    await db.into(db.xpEvents).insert(
      XpEventsCompanion.insert(
        id: 'seed',
        amount: 90,
        sourceType: 'seed',
        sourceId: 'seed',
        createdAt: now,
      ),
    );

    final result = await actions.complete(session(6000));

    expect(result!.xpGained, 20);
    expect(result.levelBefore, 1);
    expect(result.levelAfter, 2);
    expect(result.leveledUp, isTrue);
  });

  test('repository: seconds for a day and recent sessions', () async {
    await addTask('t1', 'Write report');
    await actions.complete(session(1500));
    await actions.complete(session(600, taskId: 't1', mode: FocusMode.stopwatch));

    expect(await repo.watchSecondsForDay(today).first, 2100);
    expect(await repo.watchSecondsForDay('2026-10-05').first, 0);

    final recent = await repo.watchRecent().first;
    expect(recent.length, 2);
    // Позже начавшаяся сессия первая.
    expect(recent.first.actualSeconds, 600);
    expect(recent.first.taskTitle, 'Write report');
    expect(recent.first.mode, FocusMode.stopwatch);
    expect(recent.last.actualSeconds, 1500);
    expect(recent.last.taskTitle, isNull);
  });

  test('repository respects the limit', () async {
    for (var i = 0; i < 4; i++) {
      await actions.complete(session(120 + i));
    }

    expect((await repo.watchRecent(limit: 3).first).length, 3);
  });
}