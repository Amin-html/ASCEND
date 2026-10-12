import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/features/focus/data/focus_providers.dart';
import 'package:ascend/features/focus/domain/focus_models.dart';
import 'package:ascend/features/focus/presentation/focus_screen.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/task.dart';

import '../../helpers/fake_focus_actions.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  final start = DateTime(2026, 10, 6, 10);

  Widget app({
    required FakeClock clock,
    required FakeFocusActions actions,
    List<Task> tasks = const [],
  }) {
    return ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(clock),
        focusActionsProvider.overrideWithValue(actions),
        focusSecondsForDayProvider.overrideWith(
              (ref, dayKey) => Stream.value(0),
        ),
        recentFocusProvider.overrideWith(
              (ref) => Stream.value(const <FocusSessionEntry>[]),
        ),
        tasksByDayProvider.overrideWith((ref, dayKey) => Stream.value(tasks)),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const FocusScreen()),
    );
  }

  Future<void> advance(
      WidgetTester tester,
      FakeClock clock,
      Duration by,
      ) async {
    clock.current = clock.current.add(by);
    await tester.pump(const Duration(milliseconds: 300));
  }

  late FakeClock clock;
  late FakeFocusActions actions;

  setUp(() {
    clock = FakeClock(start);
    actions = FakeFocusActions(result: sampleCompletion(5));
  });

  Future<void> open(WidgetTester tester, {List<Task> tasks = const []}) async {
    useTallScreen(tester);
    await tester.pumpWidget(app(clock: clock, actions: actions, tasks: tasks));
    await tester.pumpAndSettle();
  }

  testWidgets('setup shows the default timer and presets', (tester) async {
    await open(tester);

    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
    expect(find.text('No task'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.text('45 min'));
    await tester.pump();
    expect(find.text('45:00'), findsOneWidget);
  });

  testWidgets('stopwatch hides the presets and counts up', (tester) async {
    await open(tester);

    await tester.tap(find.text('Stopwatch'));
    await tester.pump();
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('45 min'), findsNothing);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await advance(tester, clock, const Duration(seconds: 90));

    expect(find.text('01:30'), findsOneWidget);
  });

  testWidgets('countdown runs down and can be paused', (tester) async {
    await open(tester);

    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);

    await advance(tester, clock, const Duration(minutes: 1));
    expect(find.text('24:00'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);

    await advance(tester, clock, const Duration(minutes: 5));
    expect(find.text('24:00'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pump();
    await advance(tester, clock, const Duration(minutes: 1));
    expect(find.text('23:00'), findsOneWidget);
  });

  testWidgets('finish saves the session and shows a summary', (tester) async {
    await open(tester);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await advance(tester, clock, const Duration(minutes: 10));

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    final input = actions.inputs.single;
    expect(input.actualSeconds, 600);
    expect(input.plannedSeconds, 1500);
    expect(input.mode, FocusMode.countdown);
    expect(input.startedAt, start);
    expect(input.taskId, isNull);

    expect(find.text('Session saved'), findsOneWidget);
    expect(find.text('+5 XP'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('the countdown completes by itself', (tester) async {
    await open(tester);

    await tester.tap(find.text('15 min'));
    await tester.pump();
    await tester.tap(find.text('Start'));
    await tester.pump();
    await advance(tester, clock, const Duration(minutes: 16));
    await tester.pumpAndSettle();

    expect(actions.inputs.single.actualSeconds, 900);
    expect(find.text('Session complete'), findsOneWidget);
  });

  testWidgets('a very short session is reported as too short', (tester) async {
    actions.result = null;
    await open(tester);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await advance(tester, clock, const Duration(seconds: 30));
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Session too short'), findsOneWidget);
  });

  testWidgets('discard drops the session without saving', (tester) async {
    await open(tester);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await advance(tester, clock, const Duration(minutes: 3));

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Discard session?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Discard'),
      ),
    );
    await tester.pumpAndSettle();

    expect(actions.inputs, isEmpty);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('a linked task is passed to the saved session', (tester) async {
    final created = DateTime(2026, 10, 6, 9);
    await open(
      tester,
      tasks: [
        Task(
          id: 't1',
          title: 'Write report',
          createdAt: created,
          updatedAt: created,
        ),
      ],
    );

    await tester.tap(find.text('No task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write report'));
    await tester.pumpAndSettle();
    expect(find.text('Write report'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await advance(tester, clock, const Duration(minutes: 1));
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(actions.inputs.single.taskId, 't1');
  });
}