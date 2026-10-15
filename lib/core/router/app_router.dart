import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/router/app_shell.dart';
import 'package:ascend/features/achievements/presentation/achievements_screen.dart';
import 'package:ascend/features/backup/presentation/backup_screen.dart';
import 'package:ascend/features/focus/presentation/focus_screen.dart';
import 'package:ascend/features/goals/presentation/goal_detail_screen.dart';
import 'package:ascend/features/goals/presentation/goals_screen.dart';
import 'package:ascend/features/habits/presentation/habits_screen.dart';
import 'package:ascend/features/home/presentation/home_screen.dart';
import 'package:ascend/features/notifications/presentation/notification_settings_screen.dart';
import 'package:ascend/features/planner/presentation/planner_screen.dart';
import 'package:ascend/features/profile/presentation/profile_screen.dart';
import 'package:ascend/features/profile/presentation/welcome_screen.dart';
import 'package:ascend/features/settings/data/settings_providers.dart';
import 'package:ascend/features/statistics/presentation/statistics_screen.dart';
import 'package:ascend/features/tasks/presentation/task_detail_screen.dart';
import 'package:ascend/shared/widgets/empty_state.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Роутер перепроверяет доступ, когда меняется «знакомство пройдено»
  // (например, после восстановления из backup).
  final refresh = ValueNotifier<int>(0);
  ref.listen<bool>(
    settingsProvider.select((s) => s.onboardingCompleted),
        (previous, next) => refresh.value++,
  );

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final done = ref.read(settingsProvider).onboardingCompleted;
      final path = state.uri.path;
      final onWelcome = path == AppRoutes.welcome;

      if (!done) {
        // До знакомства доступны только Welcome и экран backup:
        // на новом устройстве можно сразу восстановить данные.
        return (onWelcome || path == AppRoutes.backup)
            ? null
            : AppRoutes.welcome;
      }
      return onWelcome ? AppRoutes.home : null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: EmptyState(
        icon: Icons.explore_off_rounded,
        title: 'Page not found',
        message: 'This screen does not exist.',
        actionLabel: 'Go home',
        onAction: () => context.go(AppRoutes.home),
      ),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.planner,
                builder: (context, state) => const PlannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.goals,
                builder: (context, state) => const GoalsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => GoalDetailScreen(
                      goalId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stats,
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.backup,
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.habits,
        builder: (context, state) => const HabitsScreen(),
      ),
      GoRoute(
        path: AppRoutes.focus,
        builder: (context, state) => FocusScreen(
          taskId: state.uri.queryParameters['taskId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) => TaskDetailScreen(
          taskId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});