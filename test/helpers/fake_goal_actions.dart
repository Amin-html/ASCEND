import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/goals/domain/goal_actions.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';

class FakeGoalActions implements GoalActions {
  final List<String> calls = [];

  @override
  Future<void> saveGoal(Goal goal) async => calls.add('saveGoal:${goal.title}');

  @override
  Future<void> deleteGoal(String goalId) async =>
      calls.add('deleteGoal:$goalId');

  @override
  Future<void> setGoalStatus(String goalId, GoalStatus status) async =>
      calls.add('setGoalStatus:$goalId:${status.name}');

  @override
  Future<void> addMilestone(String goalId, String title) async =>
      calls.add('addMilestone:$goalId:$title');

  @override
  Future<void> renameMilestone(String milestoneId, String title) async =>
      calls.add('renameMilestone:$milestoneId:$title');

  @override
  Future<void> deleteMilestone(String milestoneId) async =>
      calls.add('deleteMilestone:$milestoneId');

  @override
  Future<CompletionResult?> setMilestoneDone(
      String milestoneId, {
        required bool done,
      }) async {
    calls.add('setMilestoneDone:$milestoneId:$done');
    return null;
  }
}