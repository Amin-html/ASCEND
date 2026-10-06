import 'package:ascend/features/tasks/domain/task_enums.dart';

/// Все числа геймификации в одном месте. Подбираются по ощущениям.
class XpConfig {
  const XpConfig({
    this.baseLow = 10,
    this.baseMedium = 15,
    this.baseHigh = 25,
    this.baseUrgent = 35,
    this.durationBonusPer30Min = 5,
    this.durationBonusCap = 15,
    this.milestoneXp = 100,
    this.dailyPlanBonus = 20,
    this.streakBonuses = const {3: 10, 7: 30, 14: 50, 30: 100},
    this.focusMinutesPerXp = 5,
    this.focusMaxXpPerSession = 20,
    this.habitXp = 5,
    this.levelBaseXp = 100,
    this.levelExponent = 1.5,
  });

  final int baseLow;
  final int baseMedium;
  final int baseHigh;
  final int baseUrgent;

  /// Бонус за оценку длительности: +N XP за каждые полные 30 минут.
  final int durationBonusPer30Min;
  final int durationBonusCap;

  final int milestoneXp;
  final int dailyPlanBonus;

  /// Длина streak (дней) -> бонус XP. Начисляется один раз при достижении.
  final Map<int, int> streakBonuses;

  /// 1 XP за каждые N полных минут фокуса.
  final int focusMinutesPerXp;
  final int focusMaxXpPerSession;

  /// XP за одну отметку привычки.
  final int habitXp;

  /// XP для перехода с уровня L на L+1 = levelBaseXp * L^levelExponent.
  final int levelBaseXp;
  final double levelExponent;

  int baseFor(TaskPriority priority) => switch (priority) {
    TaskPriority.low => baseLow,
    TaskPriority.medium => baseMedium,
    TaskPriority.high => baseHigh,
    TaskPriority.urgent => baseUrgent,
  };
}