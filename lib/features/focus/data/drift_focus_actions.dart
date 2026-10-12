import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/core/database/xp_ledger.dart';
import 'package:ascend/core/services/clock.dart';
import 'package:ascend/core/services/id_generator.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/focus/domain/focus_actions.dart';
import 'package:ascend/features/focus/domain/focus_models.dart';
import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';

const _focusSource = 'focus';

class DriftFocusActions implements FocusActions {
  DriftFocusActions({
    required this._db,
    required this._clock,
    required this._ids,
    required this._engine,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;
  final XpEngine _engine;

  late final XpLedger _ledger = XpLedger(_db);

  @override
  Future<CompletionResult?> complete(FocusSessionInput input) {
    if (!_engine.isFocusSessionCounted(input.actualSeconds)) {
      return Future<CompletionResult?>.value();
    }

    return _db.transaction(() async {
      final now = _clock.now();
      final dayKey = dayKeyOf(now);
      final sessionId = _ids.newId();
      final xp = _engine.xpForFocus(input.actualSeconds);
      final before = await _ledger.totalXp();

      // Задачу могли удалить, пока шла сессия.
      final taskId = input.taskId;
      final task = taskId == null
          ? null
          : await (_db.select(_db.tasks)..where((t) => t.id.equals(taskId)))
          .getSingleOrNull();

      await _db.into(_db.focusSessions).insert(
        FocusSessionsCompanion.insert(
          id: sessionId,
          startedAt: input.startedAt,
          dayKey: dayKey,
          createdAt: now,
          taskId: Value(task?.id),
          mode: Value(input.mode.index),
          plannedSeconds: Value(input.plannedSeconds),
          actualSeconds: Value(input.actualSeconds),
          endedAt: Value(now),
          xpAwarded: Value(xp),
        ),
      );

      if (task != null) {
        final minutes = input.actualSeconds ~/ 60;
        if (minutes > 0) {
          await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id)))
              .write(
            TasksCompanion(
              actualMinutes: Value((task.actualMinutes ?? 0) + minutes),
              updatedAt: Value(now),
            ),
          );
        }
      }

      if (xp > 0) {
        await _db.into(_db.xpEvents).insert(
          XpEventsCompanion.insert(
            id: _ids.newId(),
            amount: xp,
            sourceType: _focusSource,
            sourceId: sessionId,
            createdAt: now,
            note: Value('Focus ${input.actualSeconds ~/ 60} min'),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      // daily_stats — кэш: пересчитываем из сессий и журнала XP.
      final sum = _db.focusSessions.actualSeconds.sum();
      final row = await (_db.selectOnly(_db.focusSessions)
        ..addColumns([sum])
        ..where(_db.focusSessions.dayKey.equals(dayKey)))
          .getSingle();
      await _db.into(_db.dailyStats).insertOnConflictUpdate(
        DailyStatsCompanion(
          dayKey: Value(dayKey),
          focusSeconds: Value(row.read(sum) ?? 0),
        ),
      );
      await _ledger.refreshDayXp(dayKey);

      final after = await _ledger.totalXp();
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
}