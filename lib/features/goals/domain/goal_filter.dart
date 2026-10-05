import 'package:ascend/features/goals/domain/goal_models.dart';

enum GoalFilter { active, completed, archived }

/// Оставляет цели нужного статуса и сортирует их для показа.
/// Active: ближайший дедлайн первым, без дедлайна в конце.
/// Completed: недавно выполненные первыми. Archived: недавно изменённые первыми.
List<GoalWithMilestones> applyGoalFilter(
    List<GoalWithMilestones> goals,
    GoalFilter filter,
    ) {
  final status = switch (filter) {
    GoalFilter.active => GoalStatus.active,
    GoalFilter.completed => GoalStatus.completed,
    GoalFilter.archived => GoalStatus.archived,
  };

  final list = goals.where((g) => g.goal.status == status).toList();

  list.sort((a, b) {
    switch (filter) {
      case GoalFilter.active:
        final da = a.goal.deadline;
        final db = b.goal.deadline;
        if (da != null && db != null) {
          final c = da.compareTo(db);
          if (c != 0) return c;
        } else if (da != null) {
          return -1;
        } else if (db != null) {
          return 1;
        }
        return b.goal.createdAt.compareTo(a.goal.createdAt);
      case GoalFilter.completed:
        final ca = a.goal.completedAt ?? a.goal.updatedAt;
        final cb = b.goal.completedAt ?? b.goal.updatedAt;
        return cb.compareTo(ca);
      case GoalFilter.archived:
        return b.goal.updatedAt.compareTo(a.goal.updatedAt);
    }
  });

  return list;
}