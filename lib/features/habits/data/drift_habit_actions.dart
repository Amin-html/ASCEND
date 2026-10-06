import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/core/database/xp_ledger.dart';
import 'package:ascend/core/services/clock.dart';
import 'package:ascend/core/services/id_generator.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';
import 'package:ascend/features/habits/data/habit_mappers.dart';
import 'package:ascend/features/habits/domain/habit_actions.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';

const _habitSource = 'habit';

class DriftHabitActions implements HabitActions {
  DriftHabitActions({
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
  Future<void> saveHabit(Habit habit) async {
    await _db.into(_db.habits).insertOnConflictUpdate(habitToCompanion(habit));
  }

  @override
  Future<void> deleteHabit(String habitId) {
    return _db.transaction(() async {
      final days = await _ledger.removeEvents(
        _habitSource,
        where: (sourceId) => sourceId.startsWith('$habitId:'),
      );
      // Отметки удаляются каскадом.
      await (_db.delete(_db.habits)..where((h) => h.id.equals(habitId))).go();
      for (final day in days) {
        await _ledger.refreshDayXp(day);
      }
    });
  }

  @override
  Future<void> setArchived(String habitId, {required bool archived}) async {
    await (_db.update(_db.habits)..where((h) => h.id.equals(habitId))).write(
      HabitsCompanion(
        isArchived: Value(archived),
        updatedAt: Value(_clock.now()),
      ),
    );
  }

  @override
  Future<CompletionResult?> setDone(String habitId, {required bool done}) {
    return _db.transaction(() async {
      final habit = await (_db.select(_db.habits)
        ..where((h) => h.id.equals(habitId)))
          .getSingleOrNull();
      if (habit == null) return null;

      final now = _clock.now();
      final dayKey = dayKeyOf(now);
      final eventId = '$habitId:$dayKey';

      final existing = await (_db.select(_db.habitLogs)
        ..where((l) => l.habitId.equals(habitId) & l.dayKey.equals(dayKey)))
          .getSingleOrNull();

      if (!done) {
        if (existing == null) return null;
        await (_db.delete(_db.habitLogs)..where((l) => l.id.equals(existing.id)))
            .go();
        final days = await _ledger.removeEvents(
          _habitSource,
          where: (sourceId) => sourceId == eventId,
        );
        for (final day in days) {
          await _ledger.refreshDayXp(day);
        }
        return null;
      }

      if (existing != null) return null;

      final before = await _ledger.totalXp();

      await _db.into(_db.habitLogs).insert(
        HabitLogsCompanion.insert(
          id: _ids.newId(),
          habitId: habitId,
          dayKey: dayKey,
          createdAt: now,
        ),
      );
      await _db.into(_db.xpEvents).insert(
        XpEventsCompanion.insert(
          id: _ids.newId(),
          amount: habit.xpReward,
          sourceType: _habitSource,
          sourceId: eventId,
          createdAt: now,
          note: Value(habit.name),
        ),
        mode: InsertMode.insertOrReplace,
      );
      await _ledger.refreshDayXp(dayKey);

      final after = await _ledger.totalXp();
      final progressBefore = _engine.progressFor(before);
      final progressAfter = _engine.progressFor(after);

      return CompletionResult(
        taskXp: habit.xpReward,
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