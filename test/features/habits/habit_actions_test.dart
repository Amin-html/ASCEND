import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';
import 'package:ascend/features/habits/data/drift_habit_actions.dart';
import 'package:ascend/features/habits/data/drift_habit_repository.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';

import '../../helpers/fakes.dart';

void main() {
  const today = '2026-10-05';
  final created = DateTime(2026, 10, 1, 9);

  late AppDatabase db;
  late FakeClock clock;
  late DriftHabitActions actions;
  late DriftHabitRepository repo;

  Habit makeHabit(String id, {int xp = 5, int mask = 127}) {
    return Habit(
      id: id,
      name: 'Habit $id',
      weekdaysMask: mask,
      xpReward: xp,
      createdAt: created,
      updatedAt: created,
    );
  }

  Future<HabitProgress> read(String id) async {
    final all = await repo.watchAll().first;
    return all.firstWhere((p) => p.habit.id == id);
  }

  Future<int> totalXp() async {
    final events = await db.select(db.xpEvents).get();
    return events.fold<int>(0, (sum, e) => sum + e.amount);
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clock = FakeClock(DateTime(2026, 10, 5, 10));
    actions = DriftHabitActions(
      db: db,
      clock: clock,
      ids: SequentialIds(),
      engine: const XpEngine(),
    );
    repo = DriftHabitRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('saved habit is read back', () async {
    await actions.saveHabit(makeHabit('h1', mask: 31));

    final p = await read('h1');

    expect(p.habit.name, 'Habit h1');
    expect(p.habit.weekdaysMask, 31);
    expect(p.habit.isArchived, isFalse);
    expect(p.doneDays, isEmpty);
  });

  test('saving again updates the habit', () async {
    await actions.saveHabit(makeHabit('h1'));
    await actions.saveHabit(
      Habit(
        id: 'h1',
        name: 'Renamed',
        weekdaysMask: 3,
        createdAt: created,
        updatedAt: created,
      ),
    );

    final p = await read('h1');

    expect(p.habit.name, 'Renamed');
    expect(p.habit.weekdaysMask, 3);
    expect((await repo.watchAll().first).length, 1);
  });

  test('check-in awards XP and records the day', () async {
    await actions.saveHabit(makeHabit('h1'));

    final result = await actions.setDone('h1', done: true);

    expect(result, isNotNull);
    expect(result!.xpGained, 5);
    expect(result.leveledUp, isFalse);
    expect(await totalXp(), 5);
    expect((await read('h1')).doneDays, {today});
  });

  test('a big reward reports a level up', () async {
    await actions.saveHabit(makeHabit('h1', xp: 120));

    final result = await actions.setDone('h1', done: true);

    expect(result!.levelBefore, 1);
    expect(result.levelAfter, 2);
    expect(result.leveledUp, isTrue);
  });

  test('checking in twice does not award XP twice', () async {
    await actions.saveHabit(makeHabit('h1'));

    await actions.setDone('h1', done: true);
    final second = await actions.setDone('h1', done: true);

    expect(second, isNull);
    expect(await totalXp(), 5);
  });

  test('undo takes the XP back', () async {
    await actions.saveHabit(makeHabit('h1'));
    await actions.setDone('h1', done: true);

    final result = await actions.setDone('h1', done: false);

    expect(result, isNull);
    expect(await totalXp(), 0);
    expect((await read('h1')).doneDays, isEmpty);
  });

  test('undo without a check-in changes nothing', () async {
    await actions.saveHabit(makeHabit('h1'));

    expect(await actions.setDone('h1', done: false), isNull);
    expect(await totalXp(), 0);
  });

  test('unknown habit is ignored', () async {
    expect(await actions.setDone('nope', done: true), isNull);
    expect(await totalXp(), 0);
  });

  test('the next day can be checked again', () async {
    await actions.saveHabit(makeHabit('h1'));
    await actions.setDone('h1', done: true);

    clock.current = DateTime(2026, 10, 6, 10);
    final result = await actions.setDone('h1', done: true);

    expect(result, isNotNull);
    expect(await totalXp(), 10);
    expect((await read('h1')).doneDays, {'2026-10-05', '2026-10-06'});
  });

  test('undo only touches today, not earlier days', () async {
    await actions.saveHabit(makeHabit('h1'));
    await actions.setDone('h1', done: true);

    clock.current = DateTime(2026, 10, 6, 10);
    final result = await actions.setDone('h1', done: false);

    expect(result, isNull);
    expect(await totalXp(), 5);
    expect((await read('h1')).doneDays, {today});
  });

  test('daily stats follow habit XP', () async {
    await actions.saveHabit(makeHabit('h1'));

    await actions.setDone('h1', done: true);
    var stats = await (db.select(db.dailyStats)
      ..where((s) => s.dayKey.equals(today)))
        .getSingle();
    expect(stats.xpEarned, 5);

    await actions.setDone('h1', done: false);
    stats = await (db.select(db.dailyStats)
      ..where((s) => s.dayKey.equals(today)))
        .getSingle();
    expect(stats.xpEarned, 0);
  });

  test('archiving keeps history and XP', () async {
    await actions.saveHabit(makeHabit('h1'));
    await actions.setDone('h1', done: true);

    await actions.setArchived('h1', archived: true);

    final p = await read('h1');
    expect(p.habit.isArchived, isTrue);
    expect(p.doneDays, {today});
    expect(await totalXp(), 5);

    await actions.setArchived('h1', archived: false);
    expect((await read('h1')).habit.isArchived, isFalse);
  });

  test('deleting a habit removes its history and XP only', () async {
    await actions.saveHabit(makeHabit('h1'));
    await actions.saveHabit(makeHabit('h2'));
    await actions.setDone('h1', done: true);
    await actions.setDone('h2', done: true);
    expect(await totalXp(), 10);

    await actions.deleteHabit('h1');

    expect(await totalXp(), 5);
    expect((await db.select(db.habitLogs).get()).length, 1);
    final all = await repo.watchAll().first;
    expect(all.map((p) => p.habit.id), ['h2']);

    final stats = await (db.select(db.dailyStats)
      ..where((s) => s.dayKey.equals(today)))
        .getSingle();
    expect(stats.xpEarned, 5);
  });
}