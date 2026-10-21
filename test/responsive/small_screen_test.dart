import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/achievements/domain/achievement_models.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';
import 'package:ascend/features/profile/domain/user_profile.dart';
import 'package:ascend/features/settings/domain/app_settings.dart';
import 'package:ascend/features/statistics/domain/stats_models.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

import '../helpers/fake_notification_service.dart';
import '../helpers/test_app.dart';

/// Прогон ключевых экранов на узких экранах и с крупным шрифтом.
/// Тест падает, если где-то возникает RenderFlex overflow.

const _longTaskTitle =
    'Prepare the quarterly report and send it to the whole team before lunch';
const _longGoalTitle = 'Launch the first public version of the app';

final _created = DateTime(2026, 10, 1, 9);

final _tasks = [
  Task(
    id: 't1',
    title: _longTaskTitle,
    description: 'Include the numbers from every department and the forecast.',
    priority: TaskPriority.urgent,
    dayKey: '2026-10-15',
    startAt: DateTime(2026, 10, 15, 18, 30),
    reminderMinutesBefore: 30,
    estimatedMinutes: 90,
    actualMinutes: 25,
    xpReward: 50,
    createdAt: _created,
    updatedAt: _created,
  ),
  Task(
    id: 't2',
    title: 'Read',
    xpReward: 15,
    createdAt: _created,
    updatedAt: _created,
  ),
];

List<HabitProgress> _habits() {
  final today = dayKeyOf(DateTime.now());
  return [
    HabitProgress(
      habit: Habit(
        id: 'h1',
        name: 'Read twenty pages of a book every single evening',
        description: 'Fiction or non-fiction, anything counts',
        weekdaysMask: 31,
        createdAt: _created,
        updatedAt: _created,
      ),
      doneDays: {today},
    ),
    HabitProgress(
      habit: Habit(
        id: 'h2',
        name: 'Coding',
        createdAt: _created,
        updatedAt: _created,
      ),
      doneDays: const {},
    ),
  ];
}

final _goals = [
  GoalWithMilestones(
    goal: Goal(
      id: 'g1',
      title: _longGoalTitle,
      description: 'Ship it to the store and collect the first feedback.',
      deadline: DateTime.now().add(const Duration(days: 3)),
      createdAt: _created,
      updatedAt: _created,
    ),
    milestones: [
      Milestone(
        id: 'm1',
        goalId: 'g1',
        title: 'Finish the design system and all the core screens',
        sortOrder: 0,
        isDone: true,
        xpAwarded: 100,
        createdAt: _created,
        updatedAt: _created,
      ),
      Milestone(
        id: 'm2',
        goalId: 'g1',
        title: 'Test',
        sortOrder: 1,
        isDone: false,
        xpAwarded: 0,
        createdAt: _created,
        updatedAt: _created,
      ),
    ],
  ),
];

List<DayStat> _stats() {
  final now = DateTime.now();
  return [
    for (var i = 0; i < 5; i++)
      DayStat(
        dayKey: dayKeyOf(DateTime(now.year, now.month, now.day - i)),
        tasksCompleted: i + 1,
        tasksPlanned: i + 2,
        focusSeconds: 1800 * (i + 1),
        xpEarned: 40 * (i + 1),
        planCompleted: i.isEven,
      ),
  ];
}

Widget _app({FakeNotificationService? notifications, AppSettings? settings}) {
  return testApp(
    tasks: _tasks,
    habits: _habits(),
    goals: _goals,
    stats: _stats(),
    totalXp: 450,
    focusSecondsToday: 3900,
    counts: const AchievementCounts(
      completedTasks: 37,
      focusSeconds: 7300,
      totalXp: 450,
    ),
    unlocked: {'first_step': DateTime(2026, 10, 2)},
    profile: const UserProfile(name: 'Alexandra-Maria'),
    notifications: notifications,
    settings: settings ?? const AppSettings(onboardingCompleted: true),
  );
}

class _Variant {
  const _Variant(this.name, this.size, this.scale);

  final String name;
  final Size size;
  final double scale;
}

const _variants = [
  _Variant('360x640 text x1.0', Size(360, 640), 1.0),
  _Variant('360x640 text x1.5', Size(360, 640), 1.5),
  _Variant('360x640 text x2.0', Size(360, 640), 2.0),
  _Variant('320x568 text x1.3', Size(320, 568), 1.3),
];

void _setup(WidgetTester tester, _Variant v) {
  tester.view.physicalSize = v.size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = v.scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Вертикальный список экрана или листа. Внутренние прокручиваемые области
/// текстовых полей (restorationId «editable») не считаются.
Finder _mainScrollable() {
  return find.byWidgetPredicate(
        (widget) =>
    widget is Scrollable &&
        widget.axis == Axis.vertical &&
        widget.restorationId != 'editable',
  );
}

/// Прокручивает экран или лист вниз, чтобы построить всё содержимое.
Future<void> _scrollDown(WidgetTester tester) async {
  final scrollable = _mainScrollable();
  if (scrollable.evaluate().isEmpty) return;
  for (var i = 0; i < 3; i++) {
    await tester.drag(
      scrollable.last,
      const Offset(0, -1500),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: _mainScrollable().last,
    );
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Переход по адресу напрямую, без поиска и нажатия кнопки на экране.
Future<void> _go(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(location);
  await tester.pumpAndSettle();
}

void main() {
  for (final v in _variants) {
    group(v.name, () {
      Future<void> boot(
          WidgetTester tester, {
            AppSettings? settings,
            FakeNotificationService? notifications,
          }) async {
        _setup(tester, v);
        await tester.pumpWidget(
          _app(settings: settings, notifications: notifications),
        );
        await tester.pumpAndSettle();
      }

      Future<void> openCreateSheet(WidgetTester tester) async {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
      }

      testWidgets('welcome', (tester) async {
        await boot(tester, settings: const AppSettings());
        expect(find.text('Get started'), findsOneWidget);
        await _scrollDown(tester);
      });

      testWidgets('home', (tester) async {
        await boot(tester);
        expect(find.textContaining('Good'), findsOneWidget);
        await _scrollDown(tester);
      });

      testWidgets('planner', (tester) async {
        await boot(tester);
        await tester.tap(find.text('Planner'));
        await tester.pumpAndSettle();
        await _scrollDown(tester);
      });

      testWidgets('goals list', (tester) async {
        await boot(tester);
        await tester.tap(find.text('Goals'));
        await tester.pumpAndSettle();
        expect(find.text(_longGoalTitle), findsOneWidget);
        await _scrollDown(tester);
      });

      testWidgets('goal detail', (tester) async {
        await boot(tester);
        await _go(tester, AppRoutes.goalDetail('g1'));
        expect(find.text('Goal'), findsOneWidget);
        await _scrollDown(tester);
      });

      testWidgets('stats', (tester) async {
        await boot(tester);
        await tester.tap(find.text('Stats'));
        await tester.pumpAndSettle();
        await _scrollDown(tester);
      });

      testWidgets('profile', (tester) async {
        await boot(tester);
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        await _scrollDown(tester);
      });

      testWidgets('achievements', (tester) async {
        await boot(tester);
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        await _tap(tester, 'See all');
        expect(find.text('Your progress'), findsOneWidget);
        await _scrollDown(tester);
      });

      testWidgets('habits', (tester) async {
        await boot(tester);
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        await _tap(tester, 'Habits');
        await _scrollDown(tester);
      });

      testWidgets('notification settings', (tester) async {
        await boot(tester);
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        await _tap(tester, 'Notifications');
        expect(find.text('Allow notifications'), findsOneWidget);
        await _scrollDown(tester);
      });

      testWidgets('data and backup', (tester) async {
        await boot(tester);
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        await _tap(tester, 'Data & Backup');
        expect(find.text('Create a backup'), findsOneWidget);
        await _scrollDown(tester);
      });

      testWidgets('focus setup', (tester) async {
        await boot(tester);
        await _go(tester, AppRoutes.focus);
        expect(find.text('Stopwatch'), findsOneWidget);
        await _scrollDown(tester);
      });

      testWidgets('focus running', (tester) async {
        await boot(tester);
        await _go(tester, AppRoutes.focus);

        final start = find.widgetWithText(FilledButton, 'Start');
        await tester.scrollUntilVisible(
          start,
          300,
          scrollable: _mainScrollable().last,
        );
        // Нажимаем программно: важна вёрстка работающего таймера, а не попадание.
        tester.widget<FilledButton>(start.first).onPressed!();
        // Таймер идёт, поэтому pumpAndSettle здесь не годится.
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Pause'), findsOneWidget);
      });

      testWidgets('create sheet', (tester) async {
        await boot(tester);
        await openCreateSheet(tester);
        expect(find.text('New note'), findsOneWidget);
      });

      testWidgets('new task form', (tester) async {
        await boot(tester);
        await openCreateSheet(tester);
        await tester.tap(find.text('New task'));
        await tester.pumpAndSettle();
        expect(find.text('Create task'), findsOneWidget);
        await _scrollDown(tester);
      });

      testWidgets('edit task form with time and reminder', (tester) async {
        await boot(tester);
        await _tap(tester, _longTaskTitle);
        expect(find.text('Edit task'), findsOneWidget);
        await _scrollDown(tester);
      });

      testWidgets('new goal form', (tester) async {
        await boot(tester);
        await tester.tap(find.text('Goals'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('New goal'));
        await tester.pumpAndSettle();
        expect(find.text('Create goal'), findsOneWidget);
        await _scrollDown(tester);
      });

      testWidgets('new habit form', (tester) async {
        await boot(tester);
        await openCreateSheet(tester);
        await tester.tap(find.text('New habit'));
        await tester.pumpAndSettle();
        expect(find.text('Create habit'), findsOneWidget);
        await _scrollDown(tester);
      });

      testWidgets('task detail', (tester) async {
        final service = FakeNotificationService();
        await boot(tester, notifications: service);

        service.tap('task:t1');
        await tester.pumpAndSettle();
        await _scrollDown(tester);

        expect(find.text('Mark as done'), findsOneWidget);
      });
    });
  }
}