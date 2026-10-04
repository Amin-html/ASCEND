import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/database/database_providers.dart';
import 'package:ascend/features/gamification/data/drift_gamification_repository.dart';
import 'package:ascend/features/gamification/domain/gamification_repository.dart';
import 'package:ascend/features/gamification/domain/level_progress.dart';
import 'package:ascend/features/gamification/domain/streak_calculator.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';

final xpEngineProvider = Provider<XpEngine>((ref) => const XpEngine());

final gamificationRepositoryProvider = Provider<GamificationRepository>(
      (ref) => DriftGamificationRepository(ref.watch(appDatabaseProvider)),
);

final totalXpProvider = StreamProvider<int>(
      (ref) => ref.watch(gamificationRepositoryProvider).watchTotalXp(),
);

final xpForDayProvider = StreamProvider.family<int, String>(
      (ref, dayKey) =>
      ref.watch(gamificationRepositoryProvider).watchXpForDay(dayKey),
);

final activeDaysProvider = StreamProvider<Set<String>>(
      (ref) => ref.watch(gamificationRepositoryProvider).watchActiveDays(),
);

/// Уровень, XP внутри уровня и сколько осталось. Пока XP грузится, считаем 0.
final levelProgressProvider = Provider<LevelProgress>((ref) {
  final total = ref.watch(totalXpProvider).value ?? 0;
  return ref.watch(xpEngineProvider).progressFor(total);
});

final streakProvider = Provider.family<StreakInfo, String>((ref, today) {
  final days = ref.watch(activeDaysProvider).value ?? const <String>{};
  return calculateStreak(activeDays: days, today: today);
});