import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/statistics/domain/stats_models.dart';
import 'package:ascend/features/statistics/domain/stats_repository.dart';

class DriftStatsRepository implements StatsRepository {
  DriftStatsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<DayStat>> watchRange(String fromDayKey, String toDayKey) {
    final query = _db.select(_db.dailyStats)
      ..where((s) => s.dayKey.isBetweenValues(fromDayKey, toDayKey))
      ..orderBy([(s) => OrderingTerm.asc(s.dayKey)]);

    return query.watch().map(
          (rows) => [
        for (final r in rows)
          DayStat(
            dayKey: r.dayKey,
            tasksCompleted: r.tasksCompleted,
            tasksPlanned: r.tasksPlanned,
            focusSeconds: r.focusSeconds,
            xpEarned: r.xpEarned,
            planCompleted: r.planCompleted,
          ),
      ],
    );
  }
}