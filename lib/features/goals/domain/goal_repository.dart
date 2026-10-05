import 'package:ascend/features/goals/domain/goal_models.dart';

abstract interface class GoalRepository {
  /// Все цели вместе с milestones, любого статуса.
  Stream<List<GoalWithMilestones>> watchAll();

  /// null, если цели нет.
  Stream<GoalWithMilestones?> watchById(String id);
}