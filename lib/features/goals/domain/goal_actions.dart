import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';

/// Все изменения целей и milestones. Каждая операция атомарна.
abstract interface class GoalActions {
  Future<void> saveGoal(Goal goal);

  /// Удаляет цель, её milestones и XP, начисленный за них.
  /// Задачи, привязанные к цели, остаются (просто отвязываются).
  Future<void> deleteGoal(String goalId);

  /// Ручная смена статуса: выполнена, в архив, вернуть в работу.
  Future<void> setGoalStatus(String goalId, GoalStatus status);

  Future<void> addMilestone(String goalId, String title);

  Future<void> renameMilestone(String milestoneId, String title);

  Future<void> deleteMilestone(String milestoneId);

  /// Отметить или снять отметку. При выполнении возвращает результат
  /// с XP и уровнем (поле taskXp здесь означает XP за milestone).
  /// Null при снятии отметки, повторном вызове или неизвестном milestone.
  Future<CompletionResult?> setMilestoneDone(
      String milestoneId, {
        required bool done,
      });
}