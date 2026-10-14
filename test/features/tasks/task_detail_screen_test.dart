import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';
import 'package:ascend/features/tasks/presentation/task_detail_screen.dart';

import '../../helpers/fake_task_actions.dart';
import '../../helpers/test_app.dart';

void main() {
  final created = DateTime(2026, 10, 14, 8);

  const work = Category(
    id: 'cat_work',
    name: 'Work',
    colorValue: 0xFF7C3AED,
    iconKey: 'work',
  );

  Task fullTask({TaskStatus status = TaskStatus.todo, DateTime? completedAt}) {
    return Task(
      id: 't1',
      title: 'Write report',
      description: 'Quarterly numbers',
      categoryId: 'cat_work',
      priority: TaskPriority.high,
      status: status,
      dayKey: '2026-10-14',
      startAt: DateTime(2026, 10, 14, 9, 30),
      reminderMinutesBefore: 10,
      estimatedMinutes: 90,
      actualMinutes: 25,
      xpReward: 35,
      completedAt: completedAt,
      createdAt: created,
      updatedAt: created,
    );
  }

  Widget app(Task? task, FakeTaskActions actions) {
    return ProviderScope(
      overrides: [
        taskByIdProvider.overrideWith((ref, id) => Stream.value(task)),
        categoriesProvider.overrideWith((ref) => Stream.value([work])),
        taskActionsProvider.overrideWithValue(actions),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const TaskDetailScreen(taskId: 't1'),
      ),
    );
  }

  Future<void> open(
      WidgetTester tester,
      Task? task,
      FakeTaskActions actions,
      ) async {
    useTallScreen(tester);
    await tester.pumpWidget(app(task, actions));
    await tester.pumpAndSettle();
  }

  testWidgets('shows every detail of the task', (tester) async {
    await open(tester, fullTask(), FakeTaskActions());

    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('To do'), findsOneWidget);
    expect(find.text('+35 XP'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Wed, 14 Oct'), findsOneWidget);
    expect(find.text('09:30  •  10 min before'), findsOneWidget);
    expect(find.text('1 h 30 min'), findsOneWidget);
    expect(find.text('25 min'), findsOneWidget);
    expect(find.text('Quarterly numbers'), findsOneWidget);
    expect(find.text('Mark as done'), findsOneWidget);
    expect(find.text('Start focus'), findsOneWidget);
  });

  testWidgets('a bare task shows placeholders', (tester) async {
    await open(
      tester,
      Task(id: 't1', title: 'Read', createdAt: created, updatedAt: created),
      FakeTaskActions(),
    );

    expect(find.text('None'), findsOneWidget);
    expect(find.text('No date'), findsOneWidget);
    expect(find.text('Not set'), findsNWidgets(2));
    expect(find.text('Description'), findsNothing);
    expect(find.text('Focused'), findsNothing);
  });

  testWidgets('a completed task can be reopened and cannot start focus',
          (tester) async {
        final actions = FakeTaskActions();
        await open(
          tester,
          fullTask(
            status: TaskStatus.completed,
            completedAt: DateTime(2026, 10, 14, 12),
          ),
          actions,
        );

        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Finished'), findsOneWidget);
        expect(find.text('Start focus'), findsNothing);

        await tester.tap(find.text('Reopen'));
        await tester.pumpAndSettle();

        expect(actions.calls, ['reopen:t1']);
      });

  testWidgets('mark as done completes the task', (tester) async {
    final actions = FakeTaskActions();
    await open(tester, fullTask(), actions);

    await tester.tap(find.text('Mark as done'));
    await tester.pumpAndSettle();

    expect(actions.calls, ['complete:t1']);
  });

  testWidgets('a missing task shows a friendly message', (tester) async {
    await open(tester, null, FakeTaskActions());

    expect(find.text('Task not found'), findsOneWidget);
    expect(find.text('Go to planner'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation first', (tester) async {
    final actions = FakeTaskActions();
    await open(tester, fullTask(), actions);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete task?'), findsOneWidget);
    expect(actions.calls, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await tester.pumpAndSettle();

    expect(actions.calls, ['delete:t1']);
  });

  testWidgets('cancelling the confirmation keeps the task', (tester) async {
    final actions = FakeTaskActions();
    await open(tester, fullTask(), actions);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(actions.calls, isEmpty);
    expect(find.text('Write report'), findsOneWidget);
  });
}