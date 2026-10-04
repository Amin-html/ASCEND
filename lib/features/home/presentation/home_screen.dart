import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/theme/app_typography.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/gamification/domain/level_progress.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';
import 'package:ascend/features/tasks/presentation/task_card.dart';
import 'package:ascend/features/tasks/presentation/task_interactions.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/empty_state.dart';
import 'package:ascend/shared/widgets/error_state.dart';
import 'package:ascend/shared/widgets/progress_ring.dart';
import 'package:ascend/shared/widgets/xp_bar.dart';

const _maxTasksOnHome = 5;

String _greeting(int hour) {
  if (hour < 5) return 'Good night';
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).now();
    final todayKey = dayKeyOf(now);
    final tasksAsync = ref.watch(tasksByDayProvider(todayKey));
    final tasks = tasksAsync.value ?? const <Task>[];
    final progress = ref.watch(levelProgressProvider);
    final rank = ref.watch(xpEngineProvider).rankForLevel(progress.level);
    final streak = ref.watch(streakProvider(todayKey));
    final xpToday = ref.watch(xpForDayProvider(todayKey)).value ?? 0;
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final categoryById = {for (final c in categories) c.id: c};
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                96,
              ),
              children: [
                Text(_greeting(now.hour), style: text.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  longDate(now),
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _TodayCard(tasks: tasks),
                const SizedBox(height: AppSpacing.lg),
                _LevelCard(progress: progress, rankLabel: rank.label),
                const SizedBox(height: AppSpacing.lg),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: AppColors.warning,
                          value: '${streak.current}',
                          label: 'Day streak',
                          caption: 'Best: ${streak.best}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.bolt_rounded,
                          iconColor: AppColors.primaryLight,
                          value: '+$xpToday',
                          label: 'XP today',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's tasks", style: text.titleLarge),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.planner),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                tasksAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => ErrorState(
                    message: 'Could not load tasks.',
                    onRetry: () => ref.invalidate(tasksByDayProvider(todayKey)),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return EmptyState(
                        icon: Icons.checklist_rounded,
                        title: 'No tasks for today',
                        message: 'Plan your day to start earning XP.',
                        actionLabel: 'Add task',
                        onAction: () => openTaskForm(
                          context,
                          initialDayKey: todayKey,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final task in list.take(_maxTasksOnHome))
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: TaskCard(
                              key: ValueKey(task.id),
                              task: task,
                              category: categoryById[task.categoryId],
                              onToggle: () => toggleTask(context, ref, task),
                              onEdit: () => openTaskForm(
                                context,
                                task: task,
                                initialDayKey: todayKey,
                              ),
                              onDelete: () =>
                                  confirmDeleteTask(context, ref, task),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final active =
    tasks.where((t) => t.status != TaskStatus.cancelled).toList();
    final total = active.length;
    final done = active.where((t) => t.isCompleted).length;
    final fraction = total == 0 ? 0.0 : done / total;
    final available = active
        .where((t) => !t.isCompleted)
        .fold<int>(0, (sum, t) => sum + t.xpReward);

    final subtitle =
    total == 0 ? 'No tasks planned yet' : '$done of $total tasks completed';
    final hint = total == 0
        ? 'Plan your day to start earning XP'
        : available > 0
        ? '$available XP still available'
        : 'All done. Great work!';

    return AppCard(
      glow: true,
      child: Row(
        children: [
          ProgressRing(
            value: fraction,
            size: 96,
            strokeWidth: 9,
            child: Text(
              '${(fraction * 100).round()}%',
              style: AppTypography.numeric.copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's plan", style: text.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hint,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.progress, required this.rankLabel});

  final LevelProgress progress;
  final String rankLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RankChip(label: rankLabel),
              Text(
                '${progress.totalXp} XP total',
                style: text.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          XpBar(
            level: progress.level,
            currentXp: progress.xpIntoLevel,
            nextLevelXp: progress.xpForNextLevel,
          ),
        ],
      ),
    );
  }
}

class _RankChip extends StatelessWidget {
  const _RankChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.military_tech_rounded,
            size: 16,
            color: AppColors.primaryLight,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppColors.primaryLight),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.caption,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cap = caption;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTypography.numeric.copyWith(fontSize: 26)),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (cap != null)
            Text(
              cap,
              style: text.labelSmall?.copyWith(color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}