import 'package:ascend/features/gamification/domain/rank.dart';

/// Итог завершения задачи. UI на его основе показывает XP и Level Up.
class CompletionResult {
  const CompletionResult({
    required this.taskXp,
    required this.totalXpBefore,
    required this.totalXpAfter,
    required this.levelBefore,
    required this.levelAfter,
    required this.rankBefore,
    required this.rankAfter,
    required this.streakDays,
  });

  final int taskXp;
  final int totalXpBefore;
  final int totalXpAfter;
  final int levelBefore;
  final int levelAfter;
  final Rank rankBefore;
  final Rank rankAfter;
  final int streakDays;

  /// Всё начисленное этим действием: задача + бонусы.
  int get xpGained => totalXpAfter - totalXpBefore;

  /// Бонусы сверх награды за саму задачу.
  int get bonusXp => xpGained - taskXp;

  bool get leveledUp => levelAfter > levelBefore;

  bool get rankChanged => rankAfter != rankBefore;
}