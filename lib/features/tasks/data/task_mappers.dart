import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

T _enumAt<T>(List<T> values, int index) {
  if (index < 0 || index >= values.length) return values.first;
  return values[index];
}

Task taskFromRow(TaskRow r) => Task(
  id: r.id,
  title: r.title,
  description: r.description,
  categoryId: r.categoryId,
  priority: _enumAt(TaskPriority.values, r.priority),
  status: _enumAt(TaskStatus.values, r.status),
  dayKey: r.dayKey,
  startAt: r.startAt,
  estimatedMinutes: r.estimatedMinutes,
  actualMinutes: r.actualMinutes,
  xpReward: r.xpReward,
  reminderMinutesBefore: r.reminderMinutesBefore,
  completedAt: r.completedAt,
  goalId: r.goalId,
  milestoneId: r.milestoneId,
  recurrenceRuleId: r.recurrenceRuleId,
  createdAt: r.createdAt,
  updatedAt: r.updatedAt,
);

TasksCompanion taskToCompanion(Task t) => TasksCompanion(
  id: Value(t.id),
  title: Value(t.title),
  description: Value(t.description),
  categoryId: Value(t.categoryId),
  priority: Value(t.priority.index),
  status: Value(t.status.index),
  dayKey: Value(t.dayKey),
  startAt: Value(t.startAt),
  estimatedMinutes: Value(t.estimatedMinutes),
  actualMinutes: Value(t.actualMinutes),
  xpReward: Value(t.xpReward),
  reminderMinutesBefore: Value(t.reminderMinutesBefore),
  completedAt: Value(t.completedAt),
  goalId: Value(t.goalId),
  milestoneId: Value(t.milestoneId),
  recurrenceRuleId: Value(t.recurrenceRuleId),
  createdAt: Value(t.createdAt),
  updatedAt: Value(t.updatedAt),
);

Category categoryFromRow(CategoryRow r) => Category(
  id: r.id,
  name: r.name,
  colorValue: r.colorValue,
  iconKey: r.iconKey,
  isDefault: r.isDefault,
  sortOrder: r.sortOrder,
);