enum GoalStatus { active, completed, archived }

class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.categoryId,
    this.deadline,
    this.status = GoalStatus.active,
    this.completedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? categoryId;
  final DateTime? deadline;
  final GoalStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Milestone {
  const Milestone({
    required this.id,
    required this.goalId,
    required this.title,
    required this.sortOrder,
    required this.isDone,
    required this.xpAwarded,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String goalId;
  final String title;
  final int sortOrder;
  final bool isDone;
  final int xpAwarded;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class GoalWithMilestones {
  const GoalWithMilestones({
    required this.goal,
    this.milestones = const [],
  });

  final Goal goal;
  final List<Milestone> milestones;

  int get total => milestones.length;

  int get done => milestones.where((m) => m.isDone).length;

  bool get isCompleted => goal.status == GoalStatus.completed;

  /// 0.0–1.0. Без milestones цель считается либо выполненной, либо нет.
  double get progress {
    if (total == 0) return isCompleted ? 1.0 : 0.0;
    return done / total;
  }
}