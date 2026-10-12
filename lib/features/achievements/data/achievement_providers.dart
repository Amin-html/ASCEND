import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/database/database_providers.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/achievements/data/drift_achievement_actions.dart';
import 'package:ascend/features/achievements/data/drift_achievement_repository.dart';
import 'package:ascend/features/achievements/domain/achievement_actions.dart';
import 'package:ascend/features/achievements/domain/achievement_models.dart';
import 'package:ascend/features/achievements/domain/achievement_repository.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/gamification/domain/streak_calculator.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>(
      (ref) => DriftAchievementRepository(ref.watch(appDatabaseProvider)),
);

final achievementActionsProvider = Provider<AchievementActions>(
      (ref) => DriftAchievementActions(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final achievementCountsProvider = StreamProvider<AchievementCounts>(
      (ref) => ref.watch(achievementRepositoryProvider).watchCounts(),
);

final unlockedAchievementsProvider = StreamProvider<Map<String, DateTime>>(
      (ref) => ref.watch(achievementRepositoryProvider).watchUnlocked(),
);

/// null, пока данные загружаются.
final achievementMetricsProvider = Provider<AchievementMetrics?>((ref) {
  final counts = ref.watch(achievementCountsProvider).value;
  final days = ref.watch(activeDaysProvider).value;
  if (counts == null || days == null) return null;

  final today = dayKeyOf(ref.watch(clockProvider).now());
  final level = ref.watch(xpEngineProvider).progressFor(counts.totalXp).level;
  final best = calculateStreak(activeDays: days, today: today).best;

  return AchievementMetrics(
    completedTasks: counts.completedTasks,
    focusSeconds: counts.focusSeconds,
    completedGoals: counts.completedGoals,
    bestStreak: best,
    level: level,
  );
});