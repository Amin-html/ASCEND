import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/achievements/data/drift_achievement_actions.dart';
import 'package:ascend/features/achievements/data/drift_achievement_repository.dart';
import 'package:ascend/features/achievements/domain/achievement_models.dart';
import 'package:ascend/features/focus/data/drift_focus_actions.dart';
import 'package:ascend/features/focus/domain/focus_models.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';
import 'package:ascend/features/goals/data/drift_goal_actions.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';
import 'package:ascend/features/statistics/data/drift_stats_repository.dart';
import 'package:ascend/features/tasks/data/drift_task_actions.dart';
import 'package:ascend/features/tasks/domain/task.dart';

import '../../helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 10, 8, 10);

  late AppDatabase db;
  late DriftAchievementRepository repo;
  late DriftAchievementActions actions;
  late DriftTaskActions taskActions;
  late DriftFocusActions focusActions;
  late DriftGoalActions goalActions;
  late DriftStatsRepository statsRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final clock = FakeClock(now);
    // Один генератор на все действия: иначе id событий XP пересекутся.
    final ids = SequentialIds();
    const engine = XpEngine();
    repo = DriftAchievementRepository(db);
    actions = DriftAchievementActions(db: db, clock: clock);
    taskActions = DriftTaskActions(db: db, clock: clock, ids: ids, engine: engine);
    focusActions = DriftFocusActions(db: db, clock: clock, ids: ids, engine: engine);
    goalActions = DriftGoalActions(db: db, clock: clock, ids: ids, engine: engine);
    statsRepo = DriftStatsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> completeTask(String id) async {
    await taskActions.save(
      Task(id: id, title: 'Task $id', createdAt: now, updatedAt: now),
    );
    await taskActions.complete(id);
  }

  test('counts start at zero', () async {
    final counts = await repo.watchCounts().first;

    expect(counts.completedTasks, 0);
    expect(counts.focusSeconds, 0);
    expect(counts.completedGoals, 0);
    expect(counts.totalXp, 0);
  });

  test('counts reflect tasks, focus and goals', () async {
    await completeTask('t1');
    await focusActions.complete(
      FocusSessionInput(
        mode: FocusMode.countdown,
        actualSeconds: 3600,
        startedAt: now,
      ),
    );
    await goalActions.saveGoal(
      Goal(id: 'g1', title: 'Goal', createdAt: now, updatedAt: now),
    );
    await goalActions.addMilestone('g1', 'Step');
    final milestone = (await db.select(db.milestones).get()).single;
    await goalActions.setMilestoneDone(milestone.id, done: true);

    final counts = await repo.watchCounts().first;

    expect(counts.completedTasks, 1);
    expect(counts.focusSeconds, 3600);
    expect(counts.completedGoals, 1);
    // 10 за задачу + 12 за час фокуса + 100 за milestone.
    expect(counts.totalXp, 122);
  });

  test('a reopened task is not counted', () async {
    await completeTask('t1');
    await taskActions.reopen('t1');

    expect((await repo.watchCounts().first).completedTasks, 0);
  });

  test('unlockNew records new achievements once', () async {
    const metrics = AchievementMetrics(completedTasks: 1);

    final first = await actions.unlockNew(metrics);
    expect(first.map((d) => d.code), ['first_step']);

    final second = await actions.unlockNew(metrics);
    expect(second, isEmpty);

    final unlocked = await repo.watchUnlocked().first;
    expect(unlocked.keys, ['first_step']);
    expect(unlocked['first_step'], now);
  });

  test('unlockNew only adds what is newly met', () async {
    await actions.unlockNew(const AchievementMetrics(completedTasks: 1));

    final next = await actions.unlockNew(
      const AchievementMetrics(completedTasks: 100, completedGoals: 1),
    );

    expect(next.map((d) => d.code).toSet(), {'tasks_100', 'goal_crusher'});
    expect(
      (await repo.watchUnlocked().first).keys.toSet(),
      {'first_step', 'tasks_100', 'goal_crusher'},
    );
  });

  test('an unlocked achievement is kept when metrics drop', () async {
    await actions.unlockNew(const AchievementMetrics(completedTasks: 1));

    final again = await actions.unlockNew(const AchievementMetrics());

    expect(again, isEmpty);
    expect((await repo.watchUnlocked().first).keys, ['first_step']);
  });

  group('stats repository', () {
    test('returns stored days inside the range only', () async {
      await completeTask('t1');

      final inside = await statsRepo.watchRange('2026-10-01', '2026-10-31').first;
      expect(inside.length, 1);
      expect(inside.single.dayKey, '2026-10-08');
      expect(inside.single.tasksCompleted, 1);
      expect(inside.single.xpEarned, 10);

      expect(
        await statsRepo.watchRange('2026-09-01', '2026-09-30').first,
        isEmpty,
      );
    });

    test('includes focus time and is ordered by day', () async {
      await focusActions.complete(
        FocusSessionInput(
          mode: FocusMode.stopwatch,
          actualSeconds: 1500,
          startedAt: now,
        ),
      );

      final days = await statsRepo.watchRange('2026-10-01', '2026-10-31').first;

      expect(days.single.focusSeconds, 1500);
      expect(days.single.xpEarned, 5);
    });
  });
}