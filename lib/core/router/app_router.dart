import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/router/app_shell.dart';
import 'package:ascend/features/backup/presentation/backup_screen.dart';
import 'package:ascend/features/goals/presentation/goals_screen.dart';
import 'package:ascend/features/home/presentation/home_screen.dart';
import 'package:ascend/features/planner/presentation/planner_screen.dart';
import 'package:ascend/features/profile/presentation/profile_screen.dart';
import 'package:ascend/features/statistics/presentation/statistics_screen.dart';
import 'package:ascend/shared/widgets/empty_state.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
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
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});