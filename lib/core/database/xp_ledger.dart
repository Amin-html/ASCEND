import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/core/utils/day_key.dart';

/// Общие операции с журналом XP для действий, которые выдают награды.
class XpLedger {
  XpLedger(this._db);

  final AppDatabase _db;

  Future<int> totalXp() async {
    final sum = _db.xpEvents.amount.sum();
    final row =
    await (_db.selectOnly(_db.xpEvents)..addColumns([sum])).getSingle();
    return row.read(sum) ?? 0;
  }

  /// daily_stats — кэш, поэтому XP дня пересчитывается из журнала.
  Future<void> refreshDayXp(String dayKey) async {
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

  /// Удаляет события данного типа, у которых [where] вернул true.
  /// Возвращает дни, в которых XP изменился, чтобы пересчитать их статистику.
  Future<Set<String>> removeEvents(
      String sourceType, {
        required bool Function(String sourceId) where,
      }) async {
    final rows = await (_db.select(_db.xpEvents)
      ..where((e) => e.sourceType.equals(sourceType)))
        .get();
    final matching = rows.where((e) => where(e.sourceId)).toList();
    if (matching.isEmpty) return const <String>{};

    final ids = [for (final e in matching) e.id];
    for (var i = 0; i < ids.length; i += 500) {
      final end = i + 500 > ids.length ? ids.length : i + 500;
      final chunk = ids.sublist(i, end);
      await (_db.delete(_db.xpEvents)..where((e) => e.id.isIn(chunk))).go();
    }
    return {for (final e in matching) dayKeyOf(e.createdAt)};
  }
}