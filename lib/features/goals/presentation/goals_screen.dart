import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/features/goals/data/goal_providers.dart';
import 'package:ascend/features/goals/domain/goal_filter.dart';
import 'package:ascend/features/goals/presentation/goal_card.dart';
import 'package:ascend/features/goals/presentation/goal_interactions.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/shared/widgets/empty_state.dart';
import 'package:ascend/shared/widgets/error_state.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  GoalFilter _filter = GoalFilter.active;

  Widget _empty({required bool noGoalsAtAll}) {
    switch (_filter) {
      case GoalFilter.active:
        return EmptyState(
          icon: Icons.flag_outlined,
          title: noGoalsAtAll ? 'No goals yet' : 'No active goals',
          message: 'Set a goal and break it into milestones.',
          actionLabel: 'Add goal',
          onAction: () => createGoalAndOpen(context),
        );
      case GoalFilter.completed:
        return const EmptyState(
          icon: Icons.emoji_events_outlined,
          title: 'No completed goals yet',
          message: 'Finish all milestones of a goal to see it here.',
        );
      case GoalFilter.archived:
        return const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Nothing archived',
          message: 'Archived goals are kept here.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final categoryById = {for (final c in categories) c.id: c};
    final now = ref.watch(clockProvider).now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            tooltip: 'New goal',
            onPressed: () => createGoalAndOpen(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<GoalFilter>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      selectedForegroundColor: AppColors.textPrimary,
                      selectedBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.25),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: GoalFilter.active,
                        label: Text('Active'),
                      ),
                      ButtonSegment(
                        value: GoalFilter.completed,
                        label: Text('Completed'),
                      ),
                      ButtonSegment(
                        value: GoalFilter.archived,
                        label: Text('Archived'),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (selection) =>
                        setState(() => _filter = selection.first),
                  ),
                ),
              ),
              Expanded(
                child: goalsAsync.when(
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => ErrorState(
                    message: 'Could not load goals.',
                    onRetry: () => ref.invalidate(goalsProvider),
                  ),
                  data: (all) {
                    final list = applyGoalFilter(all, _filter);
                    if (list.isEmpty) {
                      return _empty(noGoalsAtAll: all.isEmpty);
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        96,
                      ),
                      itemCount: list.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return GoalCard(
                          key: ValueKey(item.goal.id),
                          item: item,
                          now: now,
                          category: categoryById[item.goal.categoryId],
                          onTap: () =>
                              context.go(AppRoutes.goalDetail(item.goal.id)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}