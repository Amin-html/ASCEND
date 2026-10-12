import 'dart:math' as math;

import 'package:ascend/features/gamification/domain/rank.dart';

/// Сырые счётчики из БД.
class AchievementCounts {
  const AchievementCounts({
    this.completedTasks = 0,
    this.focusSeconds = 0,
    this.completedGoals = 0,
    this.totalXp = 0,
  });

  final int completedTasks;
  final int focusSeconds;
  final int completedGoals;
  final int totalXp;
}

/// Всё, по чему проверяются условия достижений.
class AchievementMetrics {
  const AchievementMetrics({
    this.completedTasks = 0,
    this.focusSeconds = 0,
    this.completedGoals = 0,
    this.bestStreak = 0,
    this.level = 1,
  });

  final int completedTasks;
  final int focusSeconds;
  final int completedGoals;
  final int bestStreak;
  final int level;

  @override
  bool operator ==(Object other) =>
      other is AchievementMetrics &&
          other.completedTasks == completedTasks &&
          other.focusSeconds == focusSeconds &&
          other.completedGoals == completedGoals &&
          other.bestStreak == bestStreak &&
          other.level == level;

  @override
  int get hashCode => Object.hash(
    completedTasks,
    focusSeconds,
    completedGoals,
    bestStreak,
    level,
  );
}

class AchievementDef {
  AchievementDef({
    required this.code,
    required this.title,
    required this.description,
    required this.target,
    required this.progress,
    this.divisor = 1,
    this.prefix = '',
    this.suffix = '',
  });

  final String code;
  final String title;
  final String description;

  /// Значение метрики, при котором достижение открывается.
  final int target;
  final int Function(AchievementMetrics m) progress;

  /// Для подписи прогресса: секунды показываем часами и т.п.
  final int divisor;
  final String prefix;
  final String suffix;

  String progressLabel(int current) =>
      '$prefix${current ~/ divisor} / ${target ~/ divisor}$suffix';
}

final List<AchievementDef> achievementDefs = [
  AchievementDef(
    code: 'first_step',
    title: 'First Step',
    description: 'Complete your first task',
    target: 1,
    progress: (m) => m.completedTasks,
  ),
  AchievementDef(
    code: 'streak_7',
    title: '7 Day Focus',
    description: 'Complete tasks 7 days in a row',
    target: 7,
    progress: (m) => m.bestStreak,
    suffix: ' days',
  ),
  AchievementDef(
    code: 'tasks_100',
    title: '100 Tasks',
    description: 'Complete 100 tasks',
    target: 100,
    progress: (m) => m.completedTasks,
  ),
  AchievementDef(
    code: 'deep_worker',
    title: 'Deep Worker',
    description: 'Focus for 10 hours in total',
    target: 10 * 3600,
    progress: (m) => m.focusSeconds,
    divisor: 3600,
    suffix: ' h',
  ),
  AchievementDef(
    code: 'goal_crusher',
    title: 'Goal Crusher',
    description: 'Complete a goal',
    target: 1,
    progress: (m) => m.completedGoals,
  ),
  AchievementDef(
    code: 'elite',
    title: 'Elite',
    description: 'Reach the Elite rank (level ${Rank.elite.minLevel})',
    target: Rank.elite.minLevel,
    progress: (m) => m.level,
    prefix: 'Level ',
  ),
];

/// Достижения, условие которых выполнено, но которые ещё не открыты.
List<AchievementDef> findNewlyUnlocked(
    AchievementMetrics metrics,
    Set<String> unlockedCodes,
    ) {
  return [
    for (final d in achievementDefs)
      if (!unlockedCodes.contains(d.code) && d.progress(metrics) >= d.target) d,
  ];
}

class AchievementEntry {
  const AchievementEntry({
    required this.def,
    required this.current,
    this.unlockedAt,
  });

  final AchievementDef def;

  /// Текущее значение, не больше цели.
  final int current;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  double get fraction =>
      def.target <= 0 ? 1.0 : (current / def.target).clamp(0.0, 1.0).toDouble();
}

/// Открытым считается достижение, записанное в БД: оно остаётся открытым,
/// даже если метрики потом упали (например, удалили задачи).
List<AchievementEntry> buildAchievementEntries(
    AchievementMetrics metrics,
    Map<String, DateTime> unlockedAt,
    ) {
  return [
    for (final d in achievementDefs)
      AchievementEntry(
        def: d,
        unlockedAt: unlockedAt[d.code],
        current: unlockedAt.containsKey(d.code)
            ? d.target
            : math.min(d.progress(metrics), d.target),
      ),
  ];
}