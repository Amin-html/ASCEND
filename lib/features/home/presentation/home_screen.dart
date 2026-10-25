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
import 'package:ascend/features/focus/presentation/home_focus_card.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/gamification/domain/level_progress.dart';
import 'package:ascend/features/habits/presentation/home_habits_section.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';
import 'package:ascend/features/tasks/presentation/task_card.dart';
import 'package:ascend/features/tasks/presentation/task_interactions.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/count_up_text.dart';
import 'package:ascend/shared/widgets/empty_state.dart';
import 'package:ascend/shared/widgets/error_state.dart';
import 'package:ascend/shared/widgets/fade_slide_in.dart';
import 'package:ascend/shared/widgets/progress_ring.dart';
import 'package:ascend/shared/widgets/stat_tile.dart';
import 'package:ascend/shared/widgets/xp_bar.dart';
import 'package:ascend/features/profile/data/profile_providers.dart';
import 'package:ascend/shared/widgets/split_row.dart';

const _maxTasksOnHome = 5;

String _greeting(int hour) {
  if (hour < 5) return 'Good night';
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Ширина контента, с которой Home переходит на две колонки.
  static const double _twoColumnWidth = 860;

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
    final name = ref.watch(profileProvider).value?.name ?? '';

    final greeting = name.isEmpty
        ? _greeting(now.hour)
        : '${_greeting(now.hour)}, $name';

    // Блоки появляются каскадом: чем больше номер, тем позже.
    Widget stagger(int index, Widget child) => FadeSlideIn(
      delay: Duration(milliseconds: 70 * index),
      child: child,
    );

    final todayCard = stagger(1, _TodayCard(tasks: tasks));
    final levelCard = stagger(
      2,
      _LevelCard(progress: progress, rankLabel: rank.label),
    );
    final statsRow = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatTile(
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.warning,
              value: '${streak.current}',
              countTo: streak.current,
              label: 'Day streak',
              caption: 'Best: ${streak.best}',
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: StatTile(
              icon: Icons.bolt_rounded,
              iconColor: AppColors.primaryLight,
              value: '+$xpToday',
              countTo: xpToday,
              prefix: '+',
              label: 'XP today',
            ),
          ),
        ],
      ),
    );
    final stats = stagger(3, statsRow);
    final focusCard = stagger(4, const HomeFocusCard());
    final habitsSection = stagger(6, const HomeHabitsSection());

    final tasksColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SplitRow(
          left: Text("Today's tasks", style: text.titleLarge),
          right: TextButton(
            onPressed: () => context.go(AppRoutes.planner),
            child: const Text('See all'),
          ),
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
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                      onDelete: () => confirmDeleteTask(context, ref, task),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );

    final tasksSection = stagger(5, tasksColumn);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                96,
              ),
              children: [
                FadeSlideIn(
                  child: _HomeHero(greeting: greeting, date: longDate(now)),
                ),
                const SizedBox(height: AppSpacing.xl),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= _twoColumnWidth) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                todayCard,
                                const SizedBox(height: AppSpacing.xxl),
                                tasksSection,
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxl),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                levelCard,
                                const SizedBox(height: AppSpacing.lg),
                                stats,
                                const SizedBox(height: AppSpacing.lg),
                                focusCard,
                                const SizedBox(height: AppSpacing.xxl),
                                habitsSection,
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        todayCard,
                        const SizedBox(height: AppSpacing.lg),
                        levelCard,
                        const SizedBox(height: AppSpacing.lg),
                        stats,
                        const SizedBox(height: AppSpacing.lg),
                        focusCard,
                        const SizedBox(height: AppSpacing.xxl),
                        tasksSection,
                        const SizedBox(height: AppSpacing.xxl),
                        habitsSection,
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

/// Фирменный блок: фото гор под тёмным градиентом, приветствие и дата.
/// Высота растёт вместе с текстом, поэтому крупный шрифт ничего не ломает.
class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.greeting, required this.date});

  final String greeting;
  final String date;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadius.card);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: radius,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.1, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 1600),
              curve: AppMotion.curve,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Image.asset(
                'assets/images/ascend_mountains.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.35),
                cacheWidth: 1280,
                errorBuilder: (context, error, stack) =>
                    const ColoredBox(color: AppColors.surfaceElevated),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.04),
                    AppColors.background.withValues(alpha: 0.28),
                    AppColors.background.withValues(alpha: 0.82),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 196),
            padding: const EdgeInsets.all(AppSpacing.xl),
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineMedium?.copyWith(
                    shadows: const [
                      Shadow(color: Color(0x99000000), blurRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  date,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.85),
                    shadows: const [
                      Shadow(color: Color(0x99000000), blurRadius: 10),
                    ],
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
            child: CountUpText(
              value: (fraction * 100).round(),
              suffix: '%',
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
          SplitRow(
            left: _RankChip(label: rankLabel),
            right: Text(
              '${progress.totalXp} XP total',
              style: text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
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
