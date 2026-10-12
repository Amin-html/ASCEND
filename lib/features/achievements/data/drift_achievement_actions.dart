import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/core/services/clock.dart';
import 'package:ascend/features/achievements/domain/achievement_actions.dart';
import 'package:ascend/features/achievements/domain/achievement_models.dart';

class DriftAchievementActions implements AchievementActions {
  DriftAchievementActions({required this._db, required this._clock});

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<List<AchievementDef>> unlockNew(AchievementMetrics metrics) {
    return _db.transaction(() async {
      final rows = await (_db.select(_db.achievements)
        ..where((a) => a.unlockedAt.isNotNull()))
          .get();
      final unlocked = {for (final r in rows) r.code};

      final fresh = findNewlyUnlocked(metrics, unlocked);
      final now = _clock.now();
      for (final def in fresh) {
        await _db.into(_db.achievements).insertOnConflictUpdate(
          AchievementsCompanion(
            code: Value(def.code),
            unlockedAt: Value(now),
            progress: Value(def.target),
          ),
        );
      }
      return fresh;
    });
  }
}