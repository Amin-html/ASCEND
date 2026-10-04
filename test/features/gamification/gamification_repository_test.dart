import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/gamification/data/drift_gamification_repository.dart';

void main() {
  late AppDatabase db;
  late DriftGamificationRepository repo;

  Future<void> addXp(String id, int amount, DateTime at) {
    return db.into(db.xpEvents).insert(
      XpEventsCompanion.insert(
        id: id,
        amount: amount,
        sourceType: 'test',
        sourceId: id,
        createdAt: at,
      ),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftGamificationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('total XP sums all events', () async {
    expect(await repo.watchTotalXp().first, 0);

    await addXp('a', 20, DateTime(2026, 10, 3, 9));
    await addXp('b', 15, DateTime(2026, 10, 4, 9));

    expect(await repo.watchTotalXp().first, 35);
  });

  test('XP for a day counts only that local day', () async {
    await addXp('a', 20, DateTime(2026, 10, 3, 23, 59));
    await addXp('b', 15, DateTime(2026, 10, 4));
    await addXp('c', 5, DateTime(2026, 10, 4, 12));

    expect(await repo.watchXpForDay('2026-10-03').first, 20);
    expect(await repo.watchXpForDay('2026-10-04').first, 20);
    expect(await repo.watchXpForDay('2026-10-05').first, 0);
  });

  test('active days include only days with completed tasks', () async {
    await db.into(db.dailyStats).insert(
      DailyStatsCompanion.insert(
        dayKey: '2026-10-02',
        tasksCompleted: const Value(0),
      ),
    );
    await db.into(db.dailyStats).insert(
      DailyStatsCompanion.insert(
        dayKey: '2026-10-03',
        tasksCompleted: const Value(2),
      ),
    );

    expect(await repo.watchActiveDays().first, {'2026-10-03'});
  });
}