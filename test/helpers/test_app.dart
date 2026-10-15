import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/app.dart';
import 'package:ascend/features/achievements/data/achievement_providers.dart';
import 'package:ascend/features/achievements/domain/achievement_actions.dart';
import 'package:ascend/features/achievements/domain/achievement_models.dart';
import 'package:ascend/features/backup/data/backup_providers.dart';
import 'package:ascend/features/backup/domain/safety_backup_store.dart';
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
import 'package:ascend/features/notifications/data/notification_providers.dart';
import 'package:ascend/features/notifications/domain/notification_service.dart';
import 'package:ascend/features/profile/data/profile_providers.dart';
import 'package:ascend/features/profile/domain/profile_actions.dart';
import 'package:ascend/features/profile/domain/user_profile.dart';
import 'package:ascend/features/settings/data/settings_providers.dart';
import 'package:ascend/features/settings/domain/app_settings.dart';
import 'package:ascend/features/statistics/data/stats_providers.dart';
import 'package:ascend/features/statistics/domain/stats_models.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_actions.dart';

import 'fake_achievement_actions.dart';
import 'fake_focus_actions.dart';
import 'fake_goal_actions.dart';
import 'fake_habit_actions.dart';
import 'fake_notification_service.dart';
import 'fake_profile_actions.dart';
import 'fake_task_actions.dart';
import 'fakes.dart';

/// Приложение с подставленными данными, без SQLite.
/// По умолчанию знакомство уже пройдено: приложение стартует с Home.
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
  AppSettings settings = const AppSettings(onboardingCompleted: true),
  NotificationService? notifications,
  TaskActions? taskActions,
  UserProfile profile = const UserProfile(),
  ProfileActions? profileActions,
}) {
  return ProviderScope(
    overrides: [
      tasksByDayProvider.overrideWith((ref, dayKey) => Stream.value(tasks)),
      taskByIdProvider.overrideWith(
            (ref, id) => Stream.value(tasks.where((t) => t.id == id).firstOrNull),
      ),
      taskActionsProvider.overrideWithValue(taskActions ?? FakeTaskActions()),
      openTasksWindowProvider.overrideWith((ref) => Stream.value(tasks)),
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
      settingsRepositoryProvider.overrideWithValue(
        InMemorySettingsRepository(settings),
      ),
      notificationServiceProvider.overrideWithValue(
        notifications ?? FakeNotificationService(),
      ),
      profileProvider.overrideWith((ref) => Stream.value(profile)),
      profileActionsProvider.overrideWithValue(
        profileActions ?? FakeProfileActions(),
      ),
      safetyBackupsProvider.overrideWith(
            (ref) async => const <SafetyBackupEntry>[],
      ),
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