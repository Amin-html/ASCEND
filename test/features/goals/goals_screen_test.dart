import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/goals/domain/goal_models.dart';

import '../../helpers/fake_goal_actions.dart';
import '../../helpers/test_app.dart';

void main() {
  final t0 = DateTime(2026, 10, 1);

  Goal goal(
      String id,
      String title, {
        GoalStatus status = GoalStatus.active,
      }) {
    return Goal(
      id: id,
      title: title,
      status: status,
      createdAt: t0,
      updatedAt: t0,
      completedAt: status == GoalStatus.completed ? t0 : null,
    );
  }

  Milestone milestone(String id, String goalId, String title, {bool done = false}) {
    return Milestone(
      id: id,
      goalId: goalId,
      title: title,
      sortOrder: 0,
      isDone: done,
      xpAwarded: done ? 100 : 0,
      createdAt: t0,
      updatedAt: t0,
    );
  }

  Future<void> openGoalsTab(WidgetTester tester) async {
    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();
  }

  testWidgets('empty state when there are no goals', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    await openGoalsTab(tester);

    expect(find.text('No goals yet'), findsOneWidget);
    expect(find.text('Add goal'), findsOneWidget);
  });

  testWidgets('lists active goals with progress and filters by status',
          (tester) async {
        await tester.pumpWidget(
          testApp(
            goals: [
              GoalWithMilestones(
                goal: goal('g1', 'Launch MVP'),
                milestones: [
                  milestone('m1', 'g1', 'Design', done: true),
                  milestone('m2', 'g1', 'Build', done: true),
                  milestone('m3', 'g1', 'Test'),
                  milestone('m4', 'g1', 'Ship'),
                  milestone('m5', 'g1', 'Celebrate'),
                ],
              ),
              GoalWithMilestones(
                goal: goal('g2', 'Learn Dart', status: GoalStatus.completed),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await openGoalsTab(tester);

        expect(find.text('Launch MVP'), findsOneWidget);
        expect(find.text('2 of 5 milestones'), findsOneWidget);
        expect(find.text('Learn Dart'), findsNothing);

        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();

        expect(find.text('Learn Dart'), findsOneWidget);
        expect(find.text('Launch MVP'), findsNothing);
      });

  testWidgets('goal detail shows milestones and toggles them', (tester) async {
    final actions = FakeGoalActions();
    await tester.pumpWidget(
      testApp(
        goalActions: actions,
        goals: [
          GoalWithMilestones(
            goal: goal('g1', 'Launch MVP'),
            milestones: [
              milestone('m1', 'g1', 'Design'),
              milestone('m2', 'g1', 'Build', done: true),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await openGoalsTab(tester);

    await tester.tap(find.text('Launch MVP'));
    await tester.pumpAndSettle();

    expect(find.text('Milestones'), findsOneWidget);
    expect(find.text('Design'), findsOneWidget);
    expect(find.text('Build'), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('milestone-check-m1')));
    await tester.pumpAndSettle();

    expect(actions.calls, contains('setMilestoneDone:m1:true'));
  });

  testWidgets('goal detail adds a milestone', (tester) async {
    final actions = FakeGoalActions();
    await tester.pumpWidget(
      testApp(
        goalActions: actions,
        goals: [GoalWithMilestones(goal: goal('g1', 'Launch MVP'))],
      ),
    );
    await tester.pumpAndSettle();
    await openGoalsTab(tester);
    await tester.tap(find.text('Launch MVP'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Write the spec');
    await tester.tap(find.byTooltip('Add milestone'));
    await tester.pumpAndSettle();

    expect(actions.calls, contains('addMilestone:g1:Write the spec'));
  });

  testWidgets('goal form requires a title and saves the goal', (tester) async {
    final actions = FakeGoalActions();
    await tester.pumpWidget(testApp(goalActions: actions));
    await tester.pumpAndSettle();
    await openGoalsTab(tester);

    await tester.tap(find.byTooltip('New goal'));
    await tester.pumpAndSettle();
    expect(find.text('Create goal'), findsOneWidget);

    await tester.tap(find.text('Create goal'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a title'), findsOneWidget);
    expect(actions.calls, isEmpty);

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Run a marathon');
    await tester.tap(find.text('Create goal'));
    await tester.pumpAndSettle();

    expect(actions.calls, ['saveGoal:Run a marathon']);
  });
}