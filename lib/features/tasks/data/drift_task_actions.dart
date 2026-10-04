import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/core/services/clock.dart';
import 'package:ascend/core/services/id_generator.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/gamification/domain/streak_calculator.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';
import 'package:ascend/features/tasks/data/task_mappers.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_actions.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

typedef _DayCounts = ({int planned, int plannedDone, int completedOnDay});

const _taskSource = 'task';
const _planSource = 'daily_plan';
const _streakSource = 'streak';

class DriftTaskActions implements TaskActions {
  DriftTaskActions({
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
  Future<void> save(Task task) {
    return _db.transaction(() async {
      final previous = await _taskRow(task.id);
      await _db.into(_db.tasks).insertOnConflictUpdate(taskToCompanion(task));

      final days = <String>{};
      final newDay = task.dayKey;
      final oldDay = previous?.dayKey;
      if (newDay != null) days.add(newDay);
      if (oldDay != null) days.add(oldDay);
      for (final day in days) {
        await _writeStats(day);
      }
    });
  }

  @override
  Future<CompletionResult?> complete(String taskId) {
    return _db.transaction(() async {
      final row = await _taskRow(taskId);
      if (row == null || row.status == TaskStatus.completed.index) {
        return null;
      }

      final now = _clock.now();
      final before = await _totalXp();

      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(
          status: Value(TaskStatus.completed.index),
          completedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await _putEvent(
        sourceType: _taskSource,
        sourceId: taskId,
        amount: row.xpReward,
        now: now,
        note: row.title,
      );

      final todayKey = dayKeyOf(now);
      final days = <String>{todayKey};
      final plannedDay = row.dayKey;
      if (plannedDay != null) days.add(plannedDay);
      for (final day in days) {
        await _reconcile(day, now, allowAward: true);
      }

      final after = await _totalXp();
      final streak = await _currentStreak(todayKey);
      final progressBefore = _engine.progressFor(before);
      final progressAfter = _engine.progressFor(after);

      return CompletionResult(
        taskXp: row.xpReward,
        totalXpBefore: before,
        totalXpAfter: after,
        levelBefore: progressBefore.level,
        levelAfter: progressAfter.level,
        rankBefore: _engine.rankForLevel(progressBefore.level),
        rankAfter: _engine.rankForLevel(progressAfter.level),
        streakDays: streak,
      );
    });
  }

  @override
  Future<void> reopen(String taskId) {
    return _db.transaction(() async {
      final row = await _taskRow(taskId);
      if (row == null || row.status != TaskStatus.completed.index) return;

      final now = _clock.now();
      final completedAt = row.completedAt;

      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(
          status: Value(TaskStatus.todo.index),
          completedAt: const Value<DateTime?>(null),
          updatedAt: Value(now),
        ),
      );
      await _deleteEvent(_taskSource, taskId);

      final days = <String>{};
      if (completedAt != null) days.add(dayKeyOf(completedAt));
      final plannedDay = row.dayKey;
      if (plannedDay != null) days.add(plannedDay);
      for (final day in days) {
        await _reconcile(day, now, allowAward: false);
      }
    });
  }

  @override
  Future<void> delete(String taskId) {
    return _db.transaction(() async {
      final row = await _taskRow(taskId);
      if (row == null) return;

      final now = _clock.now();
      final completedAt = row.completedAt;

      await (_db.delete(_db.tasks)..where((t) => t.id.equals(taskId))).go();
      await _deleteEvent(_taskSource, taskId);

      final days = <String>{};
      if (completedAt != null) days.add(dayKeyOf(completedAt));
      final plannedDay = row.dayKey;
      if (plannedDay != null) days.add(plannedDay);
      for (final day in days) {
        await _reconcile(day, now, allowAward: false);
      }
    });
  }

  // ---------------------------------------------------------------------------

  Future<TaskRow?> _taskRow(String id) {
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> _totalXp() async {
    final sum = _db.xpEvents.amount.sum();
    final row =
    await (_db.selectOnly(_db.xpEvents)..addColumns([sum])).getSingle();
    return row.read(sum) ?? 0;
  }

  Future<void> _putEvent({
    required String sourceType,
    required String sourceId,
    required int amount,
    required DateTime now,
    String? note,
  }) async {
    await _db.into(_db.xpEvents).insert(
      XpEventsCompanion.insert(
        id: _ids.newId(),
        amount: amount,
        sourceType: sourceType,
        sourceId: sourceId,
        createdAt: now,
        note: Value(note),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> _deleteEvent(String sourceType, String sourceId) async {
    await (_db.delete(_db.xpEvents)
      ..where(
            (e) => e.sourceType.equals(sourceType) & e.sourceId.equals(sourceId),
      ))
        .go();
  }

  Future<bool> _hasEvent(String sourceType, String sourceId) async {
    final rows = await (_db.select(_db.xpEvents)
      ..where(
            (e) => e.sourceType.equals(sourceType) & e.sourceId.equals(sourceId),
      ))
        .get();
    return rows.isNotEmpty;
  }

  Future<int> _currentStreak(String dayKey) async {
    final rows = await (_db.select(_db.dailyStats)
      ..where((s) => s.tasksCompleted.isBiggerThanValue(0)))
        .get();
    return calculateStreak(
      activeDays: {for (final r in rows) r.dayKey},
      today: dayKey,
    ).current;
  }

  /// Пересчитывает статистику дня и приводит бонусы (план дня, streak)
  /// в соответствие с фактом. Бонусы выдаются только при завершении задачи
  /// и только за сегодняшний день, чтобы нельзя было накрутить XP задним числом.
  /// Удаляются бонусы без любых условий, если они перестали быть заслуженными.
  Future<void> _reconcile(
      String dayKey,
      DateTime now, {
        required bool allowAward,
      }) async {
    final isToday = dayKey == dayKeyOf(now);
    final counts = await _writeStats(dayKey);

    final planDone = counts.planned > 0 && counts.plannedDone == counts.planned;
    final planExists = await _hasEvent(_planSource, dayKey);
    if (planDone && !planExists && allowAward && isToday) {
      await _putEvent(
        sourceType: _planSource,
        sourceId: dayKey,
        amount: _engine.xpForDailyPlan(),
        now: now,
      );
    } else if (!planDone && planExists) {
      await _deleteEvent(_planSource, dayKey);
    }

    final streakExists = await _hasEvent(_streakSource, dayKey);
    if (counts.completedOnDay > 0) {
      if (allowAward && isToday && !streakExists) {
        final streak = await _currentStreak(dayKey);
        final bonus = _engine.xpForStreak(streak);
        if (bonus > 0) {
          await _putEvent(
            sourceType: _streakSource,
            sourceId: dayKey,
            amount: bonus,
            now: now,
          );
        }
      }
    } else if (streakExists) {
      await _deleteEvent(_streakSource, dayKey);
    }

    // Второй раз, чтобы xpEarned учитывал только что выданные бонусы.
    await _writeStats(dayKey);
  }

  /// daily_stats — кэш: всегда пересчитывается из задач и событий XP.
  Future<_DayCounts> _writeStats(String dayKey) async {
    final start = dateFromDayKey(dayKey);
    final end = DateTime(start.year, start.month, start.day + 1);
    final t = _db.tasks;

    Future<int> countTasks(Expression<bool> where) async {
      final c = t.id.count();
      final r = await (_db.selectOnly(t)
        ..addColumns([c])
        ..where(where))
          .getSingle();
      return r.read(c) ?? 0;
    }

    final planned = await countTasks(
      t.dayKey.equals(dayKey) &
      t.status.equals(TaskStatus.cancelled.index).not(),
    );
    final plannedDone = await countTasks(
      t.dayKey.equals(dayKey) & t.status.equals(TaskStatus.completed.index),
    );
    final completedOnDay = await countTasks(
      t.status.equals(TaskStatus.completed.index) &
      t.completedAt.isBiggerOrEqualValue(start) &
      t.completedAt.isSmallerThanValue(end),
    );

    final xpSum = _db.xpEvents.amount.sum();
    final xpRow = await (_db.selectOnly(_db.xpEvents)
      ..addColumns([xpSum])
      ..where(
        _db.xpEvents.createdAt.isBiggerOrEqualValue(start) &
        _db.xpEvents.createdAt.isSmallerThanValue(end),
      ))
        .getSingle();
    final xpEarned = xpRow.read(xpSum) ?? 0;

    await _db.into(_db.dailyStats).insertOnConflictUpdate(
      DailyStatsCompanion(
        dayKey: Value(dayKey),
        tasksPlanned: Value(planned),
        tasksCompleted: Value(completedOnDay),
        xpEarned: Value(xpEarned),
        planCompleted: Value(planned > 0 && plannedDone == planned),
      ),
    );

    return (
    planned: planned,
    plannedDone: plannedDone,
    completedOnDay: completedOnDay,
    );
  }
}