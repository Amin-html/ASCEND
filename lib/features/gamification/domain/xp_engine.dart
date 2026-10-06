import 'dart:math' as math;

import 'package:ascend/features/gamification/domain/level_progress.dart';
import 'package:ascend/features/gamification/domain/rank.dart';
import 'package:ascend/features/gamification/domain/xp_config.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

/// Единственное место, где живут формулы XP, уровней и рангов.
class XpEngine {
  const XpEngine([this.config = const XpConfig()]);

  final XpConfig config;

  /// XP-награда задачи. Фиксируется при создании (10–50 XP).
  int xpForNewTask({required TaskPriority priority, int? estimatedMinutes}) {
    final base = config.baseFor(priority);
    final minutes = estimatedMinutes ?? 0;
    if (minutes <= 0) return base;
    final bonus = math.min(
      (minutes ~/ 30) * config.durationBonusPer30Min,
      config.durationBonusCap,
    );
    return base + bonus;
  }

  int xpForMilestone() => config.milestoneXp;

  int xpForHabit() => config.habitXp;

  int xpForDailyPlan() => config.dailyPlanBonus;

  /// Бонус за достижение ровно такой длины streak, иначе 0.
  int xpForStreak(int streakDays) => config.streakBonuses[streakDays] ?? 0;

  int xpForFocus(int seconds) {
    if (seconds <= 0) return 0;
    final minutes = seconds ~/ 60;
    final xp = minutes ~/ config.focusMinutesPerXp;
    return math.min(xp, config.focusMaxXpPerSession);
  }

  /// Сколько XP нужно, чтобы перейти с [level] на [level] + 1.
  int xpToNextLevel(int level) {
    final l = level < 1 ? 1 : level;
    return (config.levelBaseXp * math.pow(l, config.levelExponent)).round();
  }

  /// Суммарный XP, с которого начинается [level].
  int totalXpForLevel(int level) {
    var total = 0;
    for (var k = 1; k < level; k++) {
      total += xpToNextLevel(k);
    }
    return total;
  }

  LevelProgress progressFor(int totalXp) {
    final safeTotal = totalXp < 0 ? 0 : totalXp;
    var level = 1;
    var remaining = safeTotal;
    var needed = xpToNextLevel(level);
    while (remaining >= needed) {
      remaining -= needed;
      level++;
      needed = xpToNextLevel(level);
    }
    return LevelProgress(
      level: level,
      xpIntoLevel: remaining,
      xpForNextLevel: needed,
      totalXp: safeTotal,
    );
  }

  Rank rankForLevel(int level) {
    var result = Rank.beginner;
    for (final rank in Rank.values) {
      if (level >= rank.minLevel) result = rank;
    }
    return result;
  }
}