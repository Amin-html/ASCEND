import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';
import 'package:ascend/features/goals/data/drift_goal_actions.dart';
import 'package:ascend/features/goals/data/drift_goal_repository.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';

import '../../helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 10, 5, 10);
  const today = '2026-10-05';

  late AppDatabase db;
  late DriftGoalActions actions;
  late DriftGoalRepository repo;

  Goal makeGoal(String id) {
    return Goal(id: id, title: 'Goal $id', createdAt: now, updatedAt: now);
  }

  Future<GoalWithMilestones> read(String id) async =>
      (await repo.watchById(id).first)!;

  Future<List<Milestone>> milestonesOf(String id) async =>
      (await read(id)).milestones;

  Future<int> totalXp() async {
    final events = await db.select(db.xpEvents).get();
    return events.fold<int>(0, (sum, e) => sum + e.amount);
  }

  Future<void> goalWithTwoMilestones() async {
    await actions.saveGoal(makeGoal('g1'));
    await actions.addMilestone('g1', 'Design');
    await actions.addMilestone('g1', 'Build');
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    actions = DriftGoalActions(
      db: db,
      clock: FakeClock(now),
      ids: SequentialIds(),
      engine: const XpEngine(),
    );
    repo = DriftGoalRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('saved goal is read back with milestones in order', () async {
    await goalWithTwoMilestones();

    final item = await read('g1');

    expect(item.goal.title, 'Goal g1');
    expect(item.milestones.map((m) => m.title), ['Design', 'Build']);
    expect(item.total, 2);
    expect(item.done, 0);
    expect(item.progress, 0.0);
  });

  test('watchById returns null for an unknown goal', () async {
    expect(await repo.watchById('missing').first, isNull);
  });

  test('blank milestone title is ignored', () async {
    await actions.saveGoal(makeGoal('g1'));

    await actions.addMilestone('g1', '   ');

    expect(await milestonesOf('g1'), isEmpty);
  });

  test('rename trims and ignores blank names', () async {
    await goalWithTwoMilestones();
    final first = (await milestonesOf('g1')).first;

    await actions.renameMilestone(first.id, '  Wireframes  ');
    expect((await milestonesOf('g1')).first.title, 'Wireframes');

    await actions.renameMilestone(first.id, '   ');
    expect((await milestonesOf('g1')).first.title, 'Wireframes');
  });

  test('completing a milestone gives 100 XP and reports the level up', () async {
    await goalWithTwoMilestones();
    final first = (await milestonesOf('g1')).first;

    final result = await actions.setMilestoneDone(first.id, done: true);

    expect(result, isNotNull);
    expect(result!.xpGained, 100);
    expect(result.totalXpAfter, 100);
    expect(result.levelBefore, 1);
    expect(result.levelAfter, 2);
    expect(result.leveledUp, isTrue);
    expect(await totalXp(), 100);

    final item = await read('g1');
    expect(item.done, 1);
    expect(item.progress, 0.5);
    expect(item.milestones.first.xpAwarded, 100);
    expect(item.milestones.first.completedAt, isNotNull);
  });

  test('completing twice does not award XP twice', () async {
    await goalWithTwoMilestones();
    final first = (await milestonesOf('g1')).first;

    await actions.setMilestoneDone(first.id, done: true);
    final second = await actions.setMilestoneDone(first.id, done: true);

    expect(second, isNull);
    expect(await totalXp(), 100);
  });

  test('unknown milestone is ignored', () async {
    expect(await actions.setMilestoneDone('nope', done: true), isNull);
    expect(await totalXp(), 0);
  });

  test('undoing a milestone takes the XP back', () async {
    await goalWithTwoMilestones();
    final first = (await milestonesOf('g1')).first;
    await actions.setMilestoneDone(first.id, done: true);

    final result = await actions.setMilestoneDone(first.id, done: false);

    expect(result, isNull);
    expect(await totalXp(), 0);
    final item = await read('g1');
    expect(item.done, 0);
    expect(item.milestones.first.xpAwarded, 0);
    expect(item.milestones.first.completedAt, isNull);
  });

  test('goal completes with the last milestone and reopens on undo', () async {
    await goalWithTwoMilestones();
    final milestones = await milestonesOf('g1');

    await actions.setMilestoneDone(milestones[0].id, done: true);
    expect((await read('g1')).goal.status, GoalStatus.active);

    await actions.setMilestoneDone(milestones[1].id, done: true);
    var item = await read('g1');
    expect(item.goal.status, GoalStatus.completed);
    expect(item.goal.completedAt, isNotNull);
    expect(await totalXp(), 200);

    await actions.setMilestoneDone(milestones[1].id, done: false);
    item = await read('g1');
    expect(item.goal.status, GoalStatus.active);
    expect(item.goal.completedAt, isNull);
    expect(await totalXp(), 100);
  });

  test('adding a milestone reopens a completed goal', () async {
    await actions.saveGoal(makeGoal('g1'));
    await actions.addMilestone('g1', 'Only step');
    final only = (await milestonesOf('g1')).single;
    await actions.setMilestoneDone(only.id, done: true);
    expect((await read('g1')).goal.status, GoalStatus.completed);

    await actions.addMilestone('g1', 'One more');

    expect((await read('g1')).goal.status, GoalStatus.active);
  });

  test('deleting a done milestone removes its XP', () async {
    await goalWithTwoMilestones();
    final first = (await milestonesOf('g1')).first;
    await actions.setMilestoneDone(first.id, done: true);

    await actions.deleteMilestone(first.id);

    expect(await totalXp(), 0);
    expect((await milestonesOf('g1')).length, 1);
  });

  test('deleting a goal removes milestones and their XP, keeps tasks', () async {
    await goalWithTwoMilestones();
    final first = (await milestonesOf('g1')).first;
    await actions.setMilestoneDone(first.id, done: true);
    await db.into(db.tasks).insert(
      TasksCompanion.insert(
        id: 'task1',
        title: 'Linked task',
        createdAt: now,
        updatedAt: now,
        goalId: const Value('g1'),
      ),
    );

    await actions.deleteGoal('g1');

    expect(await repo.watchById('g1').first, isNull);
    expect(await db.select(db.milestones).get(), isEmpty);
    expect(await totalXp(), 0);
    final task = await (db.select(db.tasks)..where((t) => t.id.equals('task1')))
        .getSingle();
    expect(task.goalId, isNull);
  });

  test('manual status changes', () async {
    await actions.saveGoal(makeGoal('g1'));

    await actions.setGoalStatus('g1', GoalStatus.completed);
    var goal = (await read('g1')).goal;
    expect(goal.status, GoalStatus.completed);
    expect(goal.completedAt, isNotNull);

    await actions.setGoalStatus('g1', GoalStatus.active);
    goal = (await read('g1')).goal;
    expect(goal.status, GoalStatus.active);
    expect(goal.completedAt, isNull);

    await actions.setGoalStatus('g1', GoalStatus.archived);
    expect((await read('g1')).goal.status, GoalStatus.archived);
  });

  test('restoring an archived goal with all milestones done completes it',
          () async {
        await actions.saveGoal(makeGoal('g1'));
        await actions.addMilestone('g1', 'Only step');
        final only = (await milestonesOf('g1')).single;
        await actions.setMilestoneDone(only.id, done: true);
        await actions.setGoalStatus('g1', GoalStatus.archived);

        await actions.setGoalStatus('g1', GoalStatus.active);

        expect((await read('g1')).goal.status, GoalStatus.completed);
      });

  test('archived goal ignores milestone changes', () async {
    await goalWithTwoMilestones();
    await actions.setGoalStatus('g1', GoalStatus.archived);
    final first = (await milestonesOf('g1')).first;

    await actions.setMilestoneDone(first.id, done: true);

    expect((await read('g1')).goal.status, GoalStatus.archived);
  });

  test('daily stats follow milestone XP', () async {
    await goalWithTwoMilestones();
    final first = (await milestonesOf('g1')).first;

    await actions.setMilestoneDone(first.id, done: true);
    var stats = await (db.select(db.dailyStats)
      ..where((s) => s.dayKey.equals(today)))
        .getSingle();
    expect(stats.xpEarned, 100);

    await actions.setMilestoneDone(first.id, done: false);
    stats = await (db.select(db.dailyStats)
      ..where((s) => s.dayKey.equals(today)))
        .getSingle();
    expect(stats.xpEarned, 0);
  });
}