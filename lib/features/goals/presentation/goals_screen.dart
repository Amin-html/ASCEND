import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/features/goals/data/goal_providers.dart';
import 'package:ascend/features/goals/domain/goal_filter.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';
import 'package:ascend/features/goals/presentation/goal_card.dart';
import 'package:ascend/features/goals/presentation/goal_interactions.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/shared/widgets/empty_state.dart';
import 'package:ascend/shared/widgets/error_state.dart';
import 'package:ascend/shared/widgets/fade_slide_in.dart';
import 'package:ascend/shared/widgets/page_header.dart';
import 'package:ascend/shared/widgets/segment_control.dart';

/// Ширина списка, с которой карточки целей раскладываются в две колонки.
const double _twoColumnWidth = 700;

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

  Widget _goalCard(
    GoalWithMilestones item,
    int index,
    DateTime now,
    Map<String, Category> categoryById,
  ) {
    return FadeSlideIn(
      key: ValueKey(item.goal.id),
      delay: Duration(milliseconds: 50 * (index > 6 ? 6 : index)),
      child: GoalCard(
        item: item,
        now: now,
        category: categoryById[item.goal.categoryId],
        onTap: () => context.go(AppRoutes.goalDetail(item.goal.id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final categoryById = {for (final c in categories) c.id: c};
    final now = ref.watch(clockProvider).now();

    final content = goalsAsync.when<List<Widget>>(
      loading: () => const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, stack) => [
        ErrorState(
          message: 'Could not load goals.',
          onRetry: () => ref.invalidate(goalsProvider),
        ),
      ],
      data: (all) {
        final list = applyGoalFilter(all, _filter);
        if (list.isEmpty) {
          return [_empty(noGoalsAtAll: all.isEmpty)];
        }
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  for (var i = 0; i < list.length; i++)
                    _goalCard(list[i], i, now, categoryById),
                ];
                if (constraints.maxWidth >= _twoColumnWidth) {
                  final width = (constraints.maxWidth - AppSpacing.lg) / 2;
                  return Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: [
                      for (final card in cards)
                        SizedBox(width: width, child: card),
                    ],
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      cards[i],
                    ],
                  ],
                );
              },
            ),
          ),
        ];
      },
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                PageHeader(
                  title: 'Goals',
                  actions: [
                    IconButton.filled(
                      tooltip: 'New goal',
                      onPressed: () => createGoalAndOpen(context),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: SegmentControl<GoalFilter>(
                    segments: const [
                      (GoalFilter.active, 'Active'),
                      (GoalFilter.completed, 'Completed'),
                      (GoalFilter.archived, 'Archived'),
                    ],
                    selected: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ),
                ...content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
