import 'package:ascend/features/tasks/domain/task_enums.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.categoryId,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.dayKey,
    this.startAt,
    this.estimatedMinutes,
    this.actualMinutes,
    this.xpReward = 10,
    this.reminderMinutesBefore,
    this.completedAt,
    this.goalId,
    this.milestoneId,
    this.recurrenceRuleId,
  });

  final String id;
  final String title;
  final String? description;
  final String? categoryId;
  final TaskPriority priority;
  final TaskStatus status;
  final String? dayKey;
  final DateTime? startAt;
  final int? estimatedMinutes;
  final int? actualMinutes;
  final int xpReward;
  final int? reminderMinutesBefore;
  final DateTime? completedAt;
  final String? goalId;
  final String? milestoneId;
  final String? recurrenceRuleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => status == TaskStatus.completed;
}