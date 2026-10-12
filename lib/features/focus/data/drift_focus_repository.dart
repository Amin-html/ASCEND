import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/focus/domain/focus_models.dart';
import 'package:ascend/features/focus/domain/focus_repository.dart';

FocusMode _modeAt(int index) {
  if (index < 0 || index >= FocusMode.values.length) {
    return FocusMode.countdown;
  }
  return FocusMode.values[index];
}

class DriftFocusRepository implements FocusRepository {
  DriftFocusRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<int> watchSecondsForDay(String dayKey) {
    final sum = _db.focusSessions.actualSeconds.sum();
    final query = _db.selectOnly(_db.focusSessions)
      ..addColumns([sum])
      ..where(_db.focusSessions.dayKey.equals(dayKey));
    return query.watchSingle().map((row) => row.read(sum) ?? 0);
  }

  @override
  Stream<List<FocusSessionEntry>> watchRecent({int limit = 5}) {
    final f = _db.focusSessions;
    final t = _db.tasks;
    final query = _db.select(f).join([
      leftOuterJoin(t, t.id.equalsExp(f.taskId)),
    ])
      ..orderBy([OrderingTerm.desc(f.startedAt)])
      ..limit(limit);

    return query.watch().map((rows) {
      return [
        for (final row in rows)
          FocusSessionEntry(
            id: row.readTable(f).id,
            mode: _modeAt(row.readTable(f).mode),
            actualSeconds: row.readTable(f).actualSeconds,
            startedAt: row.readTable(f).startedAt,
            xpAwarded: row.readTable(f).xpAwarded,
            taskTitle: row.readTableOrNull(t)?.title,
          ),
      ];
    });
  }
}