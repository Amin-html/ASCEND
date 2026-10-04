import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/gamification/domain/gamification_repository.dart';

class DriftGamificationRepository implements GamificationRepository {
  DriftGamificationRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<int> watchTotalXp() {
    final sum = _db.xpEvents.amount.sum();
    final query = _db.selectOnly(_db.xpEvents)..addColumns([sum]);
    return query.watchSingle().map((row) => row.read(sum) ?? 0);
  }

  @override
  Stream<int> watchXpForDay(String dayKey) {
    final start = dateFromDayKey(dayKey);
    final end = DateTime(start.year, start.month, start.day + 1);
    final sum = _db.xpEvents.amount.sum();
    final query = _db.selectOnly(_db.xpEvents)
      ..addColumns([sum])
      ..where(
        _db.xpEvents.createdAt.isBiggerOrEqualValue(start) &
        _db.xpEvents.createdAt.isSmallerThanValue(end),
      );
    return query.watchSingle().map((row) => row.read(sum) ?? 0);
  }

  @override
  Stream<Set<String>> watchActiveDays() {
    final query = _db.select(_db.dailyStats)
      ..where((s) => s.tasksCompleted.isBiggerThanValue(0));
    return query.watch().map((rows) => {for (final r in rows) r.dayKey});
  }
}