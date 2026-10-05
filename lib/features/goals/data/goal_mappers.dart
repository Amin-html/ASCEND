import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';

GoalStatus _statusAt(int index) {
  if (index < 0 || index >= GoalStatus.values.length) return GoalStatus.active;
  return GoalStatus.values[index];
}

Goal goalFromRow(GoalRow r) => Goal(
  id: r.id,
  title: r.title,
  description: r.description,
  categoryId: r.categoryId,
  deadline: r.deadline,
  status: _statusAt(r.status),
  completedAt: r.completedAt,
  createdAt: r.createdAt,
  updatedAt: r.updatedAt,
);

Milestone milestoneFromRow(MilestoneRow r) => Milestone(
  id: r.id,
  goalId: r.goalId,
  title: r.title,
  sortOrder: r.sortOrder,
  isDone: r.isDone,
  xpAwarded: r.xpAwarded,
  completedAt: r.completedAt,
  createdAt: r.createdAt,
  updatedAt: r.updatedAt,
);

GoalsCompanion goalToCompanion(Goal g) => GoalsCompanion(
  id: Value(g.id),
  title: Value(g.title),
  description: Value(g.description),
  categoryId: Value(g.categoryId),
  deadline: Value(g.deadline),
  status: Value(g.status.index),
  completedAt: Value(g.completedAt),
  createdAt: Value(g.createdAt),
  updatedAt: Value(g.updatedAt),
);