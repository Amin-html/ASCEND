import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/features/habits/data/habit_providers.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';
import 'package:ascend/features/habits/presentation/habits_screen.dart';

import '../../helpers/fake_habit_actions.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  // 5 октября 2026: понедельник.
  final now = DateTime(2026, 10, 5, 10);
  final created = DateTime(2026, 9, 1);

  Habit habit(
      String id,
      String name, {
        int mask = 127,
        bool archived = false,
      }) {
    return Habit(
      id: id,
      name: name,
      weekdaysMask: mask,
      isArchived: archived,
      createdAt: created,
      updatedAt: created,
    );
  }

  Widget app({
    List<HabitProgress> habits = const [],
    FakeHabitActions? actions,
  }) {
    return ProviderScope(
      overrides: [
        habitsProvider.overrideWith((ref) => Stream.value(habits)),
        habitActionsProvider.overrideWithValue(actions ?? FakeHabitActions()),
        clockProvider.overrideWithValue(FakeClock(now)),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const HabitsScreen()),
    );
  }

  Future<void> pump(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  final sample = [
    HabitProgress(
      habit: habit('h1', 'Read'),
      doneDays: {'2026-10-02', '2026-10-03', '2026-10-04'},
    ),
    HabitProgress(
      habit: habit('h2', 'Gym', mask: 31),
      doneDays: {'2026-10-05'},
    ),
  ];

  testWidgets('empty state', (tester) async {
    await pump(tester, app());

    expect(find.text('No habits yet'), findsOneWidget);
    expect(find.text('Add habit'), findsOneWidget);
  });

  testWidgets('lists habits with streaks and a daily summary', (tester) async {
    useTallScreen(tester);
    await pump(tester, app(habits: sample));

    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('3-day streak'), findsOneWidget);
    expect(find.text('1-day streak'), findsOneWidget);
    expect(find.text('1 of 2 done today'), findsOneWidget);
  });

  testWidgets('tapping the check toggles today', (tester) async {
    useTallScreen(tester);
    final actions = FakeHabitActions();
    await pump(tester, app(habits: sample, actions: actions));

    await tester.tap(find.byKey(const ValueKey('habit-check-h1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('habit-check-h2')));
    await tester.pumpAndSettle();

    expect(actions.calls, ['setDone:h1:true', 'setDone:h2:false']);
  });

  testWidgets('a habit that is not scheduled today has no check',
          (tester) async {
        useTallScreen(tester);
        // Только по вторникам, а сегодня понедельник.
        await pump(
          tester,
          app(
            habits: [
              HabitProgress(
                habit: habit('h3', 'Piano', mask: 2),
                doneDays: const {},
              ),
            ],
          ),
        );

        expect(find.text('Piano'), findsOneWidget);
        expect(find.byKey(const ValueKey('habit-check-h3')), findsNothing);
      });

  testWidgets('archived habits live in their own tab', (tester) async {
    useTallScreen(tester);
    await pump(
      tester,
      app(
        habits: [
          HabitProgress(
            habit: habit('h4', 'Old habit', archived: true),
            doneDays: const {},
          ),
        ],
      ),
    );

    expect(find.text('Old habit'), findsNothing);
    expect(find.text('No habits yet'), findsOneWidget);

    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();

    expect(find.text('Old habit'), findsOneWidget);
  });

  testWidgets('form requires a name and saves the habit', (tester) async {
    useTallScreen(tester);
    final actions = FakeHabitActions();
    await pump(tester, app(actions: actions));

    await tester.tap(find.byTooltip('New habit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create habit'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(actions.calls, isEmpty);

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Read book');
    await tester.tap(find.text('Create habit'));
    await tester.pumpAndSettle();

    expect(actions.calls, ['saveHabit:Read book']);
  });

  testWidgets('form needs at least one weekday', (tester) async {
    useTallScreen(tester);
    await pump(tester, app());

    await tester.tap(find.byTooltip('New habit'));
    await tester.pumpAndSettle();

    for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      await tester.tap(find.widgetWithText(FilterChip, day));
      await tester.pump();
    }

    expect(find.text('Pick at least one day'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create habit'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Home links to the habits screen', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();

    expect(find.byType(HabitsScreen), findsOneWidget);
  });
}