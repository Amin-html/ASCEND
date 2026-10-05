import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/core/services/clock.dart';
import 'package:ascend/core/services/id_generator.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';
import 'package:ascend/features/goals/data/goal_mappers.dart';
import 'package:ascend/features/goals/domain/goal_actions.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';

const _milestoneSource = 'milestone';

class DriftGoalActions implements GoalActions {
  DriftGoalActions({
    required this._db,
    required this._clock,
    required this._ids,
    required this._engine,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;
  final XpEngine _engine;

  @override
  Future<void> saveGoal(Goal goal) async {
    await _db.into(_db.goals).insertOnConflictUpdate(goalToCompanion(goal));
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    await _db.transaction(() async {
      final rows = await (_db.select(_db.milestones)
        ..where((m) => m.goalId.equals(goalId)))
          .get();

      final days = <String>{};
      for (final m in rows) {
        days.addAll(await _removeMilestoneEvents(m.id));
      }

      // Milestones удаляются каскадом, а у задач цель сбрасывается в null.
      await (_db.delete(_db.goals)..where((g) => g.id.equals(goalId))).go();

      for (final day in days) {
        await _refreshXpForDay(day);
      }
    });
  }

  @override
  Future<void> setGoalStatus(String goalId, GoalStatus status) async {
    await _db.transaction(() async {
      final goal = await _goalRow(goalId);
      if (goal == null) return;

      await _writeStatus(goalId, status, _clock.now());

      // Из архива цель с выполненными milestones возвращается выполненной.
      if (status == GoalStatus.active &&
          goal.status == GoalStatus.archived.index) {
        await _reconcileGoal(goalId);
      }
    });
  }

  @override
  Future<void> addMilestone(String goalId, String title) async {
    final clean = title.trim();
    if (clean.isEmpty) return;

    await _db.transaction(() async {
      final maxOrder = _db.milestones.sortOrder.max();
      final row = await (_db.selectOnly(_db.milestones)
        ..addColumns([maxOrder])
        ..where(_db.milestones.goalId.equals(goalId)))
          .getSingle();
      final next = (row.read(maxOrder) ?? -1) + 1;

      final now = _clock.now();
      await _db.into(_db.milestones).insert(
        MilestonesCompanion.insert(
          id: _ids.newId(),
          goalId: goalId,
          title: clean,
          sortOrder: Value(next),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _reconcileGoal(goalId);
    });
  }

  @override
  Future<void> renameMilestone(String milestoneId, String title) async {
    final clean = title.trim();
    if (clean.isEmpty) return;

    await (_db.update(_db.milestones)..where((m) => m.id.equals(milestoneId)))
        .write(
      MilestonesCompanion(
        title: Value(clean),
        updatedAt: Value(_clock.now()),
      ),
    );
  }

  @override
  Future<void> deleteMilestone(String milestoneId) async {
    await _db.transaction(() async {
      final row = await _milestoneRow(milestoneId);
      if (row == null) return;

      final days = await _removeMilestoneEvents(milestoneId);
      await (_db.delete(_db.milestones)..where((m) => m.id.equals(milestoneId)))
          .go();

      for (final day in days) {
        await _refreshXpForDay(day);
      }
      await _reconcileGoal(row.goalId);
    });
  }

  @override
  Future<CompletionResult?> setMilestoneDone(
      String milestoneId, {
        required bool done,
      }) {
    return _db.transaction(() async {
      final row = await _milestoneRow(milestoneId);
      if (row == null || row.isDone == done) return null;

      final now = _clock.now();

      if (!done) {
        final days = await _removeMilestoneEvents(milestoneId);
        await (_db.update(_db.milestones)
          ..where((m) => m.id.equals(milestoneId)))
            .write(
          MilestonesCompanion(
            isDone: const Value(false),
            completedAt: const Value<DateTime?>(null),
            xpAwarded: const Value(0),
            updatedAt: Value(now),
          ),
        );
        for (final day in days) {
          await _refreshXpForDay(day);
        }
        await _reconcileGoal(row.goalId);
        return null;
      }

      final xp = _engine.xpForMilestone();
      final before = await _totalXp();

      await (_db.update(_db.milestones)..where((m) => m.id.equals(milestoneId)))
          .write(
        MilestonesCompanion(
          isDone: const Value(true),
          completedAt: Value(now),
          xpAwarded: Value(xp),
          updatedAt: Value(now),
        ),
      );
      await _db.into(_db.xpEvents).insert(
        XpEventsCompanion.insert(
          id: _ids.newId(),
          amount: xp,
          sourceType: _milestoneSource,
          sourceId: milestoneId,
          createdAt: now,
          note: Value(row.title),
        ),
        mode: InsertMode.insertOrReplace,
      );
      await _refreshXpForDay(dayKeyOf(now));
      await _reconcileGoal(row.goalId);

      final after = await _totalXp();
      final progressBefore = _engine.progressFor(before);
      final progressAfter = _engine.progressFor(after);

      return CompletionResult(
        taskXp: xp,
        totalXpBefore: before,
        totalXpAfter: after,
        levelBefore: progressBefore.level,
        levelAfter: progressAfter.level,
        rankBefore: _engine.rankForLevel(progressBefore.level),
        rankAfter: _engine.rankForLevel(progressAfter.level),
        streakDays: 0,
      );
    });
  }

  // ---------------------------------------------------------------------------

  Future<GoalRow?> _goalRow(String id) {
    return (_db.select(_db.goals)..where((g) => g.id.equals(id)))
        .getSingleOrNull();
  }

  Future<MilestoneRow?> _milestoneRow(String id) {
    return (_db.select(_db.milestones)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> _writeStatus(
      String goalId,
      GoalStatus status,
      DateTime now,
      ) async {
    await (_db.update(_db.goals)..where((g) => g.id.equals(goalId))).write(
      GoalsCompanion(
        status: Value(status.index),
        completedAt: Value<DateTime?>(
          status == GoalStatus.completed ? now : null,
        ),
        updatedAt: Value(now),
      ),
    );
  }

  /// Цель с milestones выполнена, когда выполнены все. Архив не трогаем.
  Future<void> _reconcileGoal(String goalId) async {
    final goal = await _goalRow(goalId);
    if (goal == null || goal.status == GoalStatus.archived.index) return;

    final milestones = await (_db.select(_db.milestones)
      ..where((m) => m.goalId.equals(goalId)))
        .get();
    if (milestones.isEmpty) return;

    final allDone = milestones.every((m) => m.isDone);
    final now = _clock.now();

    if (allDone && goal.status == GoalStatus.active.index) {
      await _writeStatus(goalId, GoalStatus.completed, now);
    } else if (!allDone && goal.status == GoalStatus.completed.index) {
      await _writeStatus(goalId, GoalStatus.active, now);
    }
  }

  Future<Set<String>> _removeMilestoneEvents(String milestoneId) async {
    final events = await (_db.select(_db.xpEvents)
      ..where(
            (e) =>
        e.sourceType.equals(_milestoneSource) &
        e.sourceId.equals(milestoneId),
      ))
        .get();
    if (events.isEmpty) return const <String>{};

    await (_db.delete(_db.xpEvents)
      ..where(
            (e) =>
        e.sourceType.equals(_milestoneSource) &
        e.sourceId.equals(milestoneId),
      ))
        .go();
    return {for (final e in events) dayKeyOf(e.createdAt)};
  }

  Future<int> _totalXp() async {
    final sum = _db.xpEvents.amount.sum();
    final row =
    await (_db.selectOnly(_db.xpEvents)..addColumns([sum])).getSingle();
    return row.read(sum) ?? 0;
  }

  /// daily_stats — кэш, поэтому XP дня пересчитывается из журнала событий.
  Future<void> _refreshXpForDay(String dayKey) async {
    final start = dateFromDayKey(dayKey);
    final end = DateTime(start.year, start.month, start.day + 1);
    final sum = _db.xpEvents.amount.sum();
    final row = await (_db.selectOnly(_db.xpEvents)
      ..addColumns([sum])
      ..where(
        _db.xpEvents.createdAt.isBiggerOrEqualValue(start) &
        _db.xpEvents.createdAt.isSmallerThanValue(end),
      ))
        .getSingle();

    await _db.into(_db.dailyStats).insertOnConflictUpdate(
      DailyStatsCompanion(
        dayKey: Value(dayKey),
        xpEarned: Value(row.read(sum) ?? 0),
      ),
    );
  }
}