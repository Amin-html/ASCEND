import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/app.dart';
import 'package:ascend/features/achievements/data/achievement_providers.dart';
import 'package:ascend/features/achievements/domain/achievement_actions.dart';
import 'package:ascend/features/achievements/domain/achievement_models.dart';
import 'package:ascend/features/focus/data/focus_providers.dart';
import 'package:ascend/features/focus/domain/focus_actions.dart';
import 'package:ascend/features/focus/domain/focus_models.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/goals/data/goal_providers.dart';
import 'package:ascend/features/goals/domain/goal_actions.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';
import 'package:ascend/features/habits/data/habit_providers.dart';
import 'package:ascend/features/habits/domain/habit_actions.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';
import 'package:ascend/features/statistics/data/stats_providers.dart';
import 'package:ascend/features/statistics/domain/stats_models.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/task.dart';

import 'fake_achievement_actions.dart';
import 'fake_focus_actions.dart';
import 'fake_goal_actions.dart';
import 'fake_habit_actions.dart';

/// Приложение с подставленными данными, без SQLite.
Widget testApp({
  List<Task> tasks = const [],
  int totalXp = 0,
  List<GoalWithMilestones> goals = const [],
  GoalActions? goalActions,
  List<HabitProgress> habits = const [],
  HabitActions? habitActions,
  int focusSecondsToday = 0,
  FocusActions? focusActions,
  AchievementCounts? counts,
  Map<String, DateTime> unlocked = const {},
  AchievementActions? achievementActions,
  List<DayStat> stats = const [],
}) {
  return ProviderScope(
    overrides: [
      tasksByDayProvider.overrideWith((ref, dayKey) => Stream.value(tasks)),
      categoriesProvider.overrideWith(
            (ref) => Stream.value(const <Category>[]),
      ),
      totalXpProvider.overrideWith((ref) => Stream.value(totalXp)),
      xpForDayProvider.overrideWith((ref, dayKey) => Stream.value(0)),
      activeDaysProvider.overrideWith(
            (ref) => Stream.value(const <String>{}),
      ),
      goalsProvider.overrideWith((ref) => Stream.value(goals)),
      goalProvider.overrideWith(
            (ref, id) =>
            Stream.value(goals.where((g) => g.goal.id == id).firstOrNull),
      ),
      goalActionsProvider.overrideWithValue(goalActions ?? FakeGoalActions()),
      habitsProvider.overrideWith((ref) => Stream.value(habits)),
      habitActionsProvider.overrideWithValue(
        habitActions ?? FakeHabitActions(),
      ),
      focusSecondsForDayProvider.overrideWith(
            (ref, dayKey) => Stream.value(focusSecondsToday),
      ),
      recentFocusProvider.overrideWith(
            (ref) => Stream.value(const <FocusSessionEntry>[]),
      ),
      focusActionsProvider.overrideWithValue(
        focusActions ?? FakeFocusActions(),
      ),
      achievementCountsProvider.overrideWith(
            (ref) => Stream.value(counts ?? AchievementCounts(totalXp: totalXp)),
      ),
      unlockedAchievementsProvider.overrideWith(
            (ref) => Stream.value(unlocked),
      ),
      achievementActionsProvider.overrideWithValue(
        achievementActions ?? FakeAchievementActions(),
      ),
      statsRangeProvider.overrideWith((ref, days) => Stream.value(stats)),
    ],
    child: const AscendApp(),
  );
}

/// Высокое окно, чтобы ListView построил все секции.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}