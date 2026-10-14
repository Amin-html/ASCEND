import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/features/settings/data/settings_providers.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/presentation/task_form_sheet.dart';

import '../../helpers/fake_task_actions.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  final now = DateTime(2026, 10, 13, 10);

  Widget app(FakeTaskActions actions, {Task? task}) {
    return ProviderScope(
      overrides: [
        taskActionsProvider.overrideWithValue(actions),
        categoriesProvider.overrideWith(
              (ref) => Stream.value(const <Category>[]),
        ),
        clockProvider.overrideWithValue(FakeClock(now)),
        settingsRepositoryProvider.overrideWithValue(
          InMemorySettingsRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showTaskFormSheet(context, task: task),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester, FakeTaskActions actions, {Task? task}) async {
    useTallScreen(tester);
    await tester.pumpWidget(app(actions, task: task));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a time and a reminder are saved with the task', (tester) async {
    final actions = FakeTaskActions();
    await open(tester, actions);

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Call Anna');
    await tester.tap(find.text('Set time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('09:00'), findsOneWidget);

    await tester.tap(find.text('30 min before'));
    await tester.pump();
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();

    final saved = actions.saved.single;
    expect(saved.title, 'Call Anna');
    expect(saved.dayKey, '2026-10-13');
    expect(saved.startAt, DateTime(2026, 10, 13, 9));
    expect(saved.reminderMinutesBefore, 30);
  });

  testWidgets('the default reminder is preselected', (tester) async {
    final actions = FakeTaskActions();
    await open(tester, actions);

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Call Anna');
    await tester.tap(find.text('Set time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();

    expect(actions.saved.single.reminderMinutesBefore, 10);
  });

  testWidgets('without a time there is no reminder', (tester) async {
    final actions = FakeTaskActions();
    await open(tester, actions);

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Read');
    expect(find.text('Reminder'), findsNothing);
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();

    final saved = actions.saved.single;
    expect(saved.startAt, isNull);
    expect(saved.reminderMinutesBefore, isNull);
  });

  testWidgets('a task without a date cannot have a time', (tester) async {
    final actions = FakeTaskActions();
    await open(tester, actions);
    expect(find.text('Set time'), findsOneWidget);

    await tester.tap(find.text('No date'));
    await tester.pump();

    expect(find.text('Set time'), findsNothing);
  });

  testWidgets('editing keeps the time and the reminder', (tester) async {
    final actions = FakeTaskActions();
    final task = Task(
      id: 't1',
      title: 'Existing',
      dayKey: '2026-10-13',
      startAt: DateTime(2026, 10, 13, 14, 30),
      reminderMinutesBefore: 5,
      createdAt: now,
      updatedAt: now,
    );
    await open(tester, actions, task: task);

    expect(find.text('14:30'), findsOneWidget);

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final saved = actions.saved.single;
    expect(saved.id, 't1');
    expect(saved.startAt, DateTime(2026, 10, 13, 14, 30));
    expect(saved.reminderMinutesBefore, 5);
  });
}