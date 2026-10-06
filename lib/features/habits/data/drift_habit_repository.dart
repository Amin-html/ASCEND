import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/habits/data/habit_mappers.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';
import 'package:ascend/features/habits/domain/habit_repository.dart';

class DriftHabitRepository implements HabitRepository {
  DriftHabitRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<HabitProgress>> watchAll() {
    final query = _db.select(_db.habits).join([
      leftOuterJoin(
        _db.habitLogs,
        _db.habitLogs.habitId.equalsExp(_db.habits.id),
      ),
    ])
      ..orderBy([
        OrderingTerm.asc(_db.habits.createdAt),
        OrderingTerm.asc(_db.habits.id),
      ]);

    return query.watch().map((rows) {
      final habits = <String, Habit>{};
      final days = <String, Set<String>>{};

      for (final row in rows) {
        final habitRow = row.readTable(_db.habits);
        habits.putIfAbsent(habitRow.id, () => habitFromRow(habitRow));
        final set = days.putIfAbsent(habitRow.id, () => <String>{});
        final log = row.readTableOrNull(_db.habitLogs);
        if (log != null) set.add(log.dayKey);
      }

      return [
        for (final entry in habits.entries)
          HabitProgress(
            habit: entry.value,
            doneDays: days[entry.key] ?? const <String>{},
          ),
      ];
    });
  }
}