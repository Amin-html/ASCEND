import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/goals/domain/goal_filter.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';
import 'package:ascend/features/goals/presentation/goal_labels.dart';

void main() {
  final t0 = DateTime(2026, 10, 1);

  Goal goal(
      String id, {
        GoalStatus status = GoalStatus.active,
        DateTime? deadline,
        DateTime? createdAt,
        DateTime? completedAt,
        DateTime? updatedAt,
      }) {
    return Goal(
      id: id,
      title: 'Goal $id',
      status: status,
      deadline: deadline,
      completedAt: completedAt,
      createdAt: createdAt ?? t0,
      updatedAt: updatedAt ?? t0,
    );
  }

  Milestone milestone(String id, {required bool done}) {
    return Milestone(
      id: id,
      goalId: 'g',
      title: id,
      sortOrder: 0,
      isDone: done,
      xpAwarded: done ? 100 : 0,
      createdAt: t0,
      updatedAt: t0,
    );
  }

  group('progress', () {
    test('counts done milestones', () {
      final item = GoalWithMilestones(
        goal: goal('g'),
        milestones: [
          milestone('a', done: true),
          milestone('b', done: false),
          milestone('c', done: false),
          milestone('d', done: true),
        ],
      );

      expect(item.total, 4);
      expect(item.done, 2);
      expect(item.progress, 0.5);
    });

    test('without milestones it depends on the status', () {
      expect(GoalWithMilestones(goal: goal('g')).progress, 0.0);
      expect(
        GoalWithMilestones(
          goal: goal('g', status: GoalStatus.completed),
        ).progress,
        1.0,
      );
    });
  });

  group('applyGoalFilter', () {
    test('active goals: nearest deadline first, no deadline last', () {
      final goals = [
        GoalWithMilestones(goal: goal('none', createdAt: DateTime(2026, 10, 3))),
        GoalWithMilestones(goal: goal('late', deadline: DateTime(2026, 12, 1))),
        GoalWithMilestones(goal: goal('soon', deadline: DateTime(2026, 10, 10))),
        GoalWithMilestones(goal: goal('none2', createdAt: DateTime(2026, 10, 5))),
      ];

      final result = applyGoalFilter(goals, GoalFilter.active);

      expect(
        result.map((g) => g.goal.id),
        ['soon', 'late', 'none2', 'none'],
      );
    });

    test('filters by status', () {
      final goals = [
        GoalWithMilestones(goal: goal('a')),
        GoalWithMilestones(goal: goal('b', status: GoalStatus.completed)),
        GoalWithMilestones(goal: goal('c', status: GoalStatus.archived)),
      ];

      expect(
        applyGoalFilter(goals, GoalFilter.active).map((g) => g.goal.id),
        ['a'],
      );
      expect(
        applyGoalFilter(goals, GoalFilter.completed).map((g) => g.goal.id),
        ['b'],
      );
      expect(
        applyGoalFilter(goals, GoalFilter.archived).map((g) => g.goal.id),
        ['c'],
      );
    });

    test('completed goals: most recently completed first', () {
      final goals = [
        GoalWithMilestones(
          goal: goal(
            'old',
            status: GoalStatus.completed,
            completedAt: DateTime(2026, 9, 1),
          ),
        ),
        GoalWithMilestones(
          goal: goal(
            'new',
            status: GoalStatus.completed,
            completedAt: DateTime(2026, 10, 1),
          ),
        ),
      ];

      expect(
        applyGoalFilter(goals, GoalFilter.completed).map((g) => g.goal.id),
        ['new', 'old'],
      );
    });
  });

  group('deadlineInfo', () {
    final now = DateTime(2026, 10, 5, 15);

    test('no deadline', () {
      final info = deadlineInfo(null, now);
      expect(info.label, 'No deadline');
      expect(info.tone, DeadlineTone.none);
    });

    test('today, tomorrow and soon', () {
      expect(deadlineInfo(DateTime(2026, 10, 5), now).label, 'Due today');
      expect(deadlineInfo(DateTime(2026, 10, 6), now).label, 'Due tomorrow');
      expect(deadlineInfo(DateTime(2026, 10, 9), now).label, 'Due in 4 days');
      expect(deadlineInfo(DateTime(2026, 10, 12), now).label, 'Due in 7 days');
      expect(deadlineInfo(DateTime(2026, 10, 9), now).tone, DeadlineTone.soon);
    });

    test('far deadline shows the date', () {
      final info = deadlineInfo(DateTime(2026, 10, 13), now);
      expect(info.label, 'Due Tue, 13 Oct');
      expect(info.tone, DeadlineTone.normal);
    });

    test('overdue', () {
      final one = deadlineInfo(DateTime(2026, 10, 4), now);
      expect(one.label, 'Overdue by 1 day');
      expect(one.tone, DeadlineTone.overdue);
      expect(deadlineInfo(DateTime(2026, 10, 2), now).label, 'Overdue by 3 days');
    });
  });
}