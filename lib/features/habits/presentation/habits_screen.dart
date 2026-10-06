import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/habits/data/habit_providers.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';
import 'package:ascend/features/habits/presentation/habit_card.dart';
import 'package:ascend/features/habits/presentation/habit_interactions.dart';
import 'package:ascend/shared/widgets/empty_state.dart';
import 'package:ascend/shared/widgets/error_state.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider).now();
    final todayKey = dayKeyOf(now);
    final async = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            tooltip: 'New habit',
            onPressed: () => createHabit(context),
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
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      selectedForegroundColor: AppColors.textPrimary,
                      selectedBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.25),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    segments: const [
                      ButtonSegment(value: false, label: Text('Active')),
                      ButtonSegment(value: true, label: Text('Archived')),
                    ],
                    selected: {_showArchived},
                    onSelectionChanged: (selection) =>
                        setState(() => _showArchived = selection.first),
                  ),
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => ErrorState(
                    message: 'Could not load habits.',
                    onRetry: () => ref.invalidate(habitsProvider),
                  ),
                  data: (all) {
                    final list = all
                        .where((p) => p.habit.isArchived == _showArchived)
                        .toList();

                    if (list.isEmpty) {
                      return _showArchived
                          ? const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Nothing archived',
                        message: 'Archived habits are kept here.',
                      )
                          : EmptyState(
                        icon: Icons.repeat_rounded,
                        title: 'No habits yet',
                        message: 'Small daily actions build big streaks.',
                        actionLabel: 'Add habit',
                        onAction: () => createHabit(context),
                      );
                    }

                    final scheduled = _showArchived
                        ? const <HabitProgress>[]
                        : list.where((p) => p.habit.isScheduledOn(now)).toList();
                    final done =
                        scheduled.where((p) => p.isDoneOn(todayKey)).length;
                    final showSummary = scheduled.isNotEmpty;
                    final offset = showSummary ? 1 : 0;

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        96,
                      ),
                      itemCount: list.length + offset,
                      separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        if (showSummary && index == 0) {
                          return _TodaySummary(
                            done: done,
                            total: scheduled.length,
                          );
                        }
                        final p = list[index - offset];
                        return HabitCard(
                          key: ValueKey(p.habit.id),
                          progress: p,
                          today: now,
                          showWeek: true,
                          archived: _showArchived,
                          onToggle: () =>
                              toggleHabitToday(context, ref, p, todayKey),
                          onEdit: () => editHabit(context, p.habit),
                          onArchive: () => setHabitArchived(
                            context,
                            ref,
                            p.habit,
                            archived: !_showArchived,
                          ),
                          onDelete: () => confirmDeleteHabit(context, ref, p),
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

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fraction = total == 0 ? 0.0 : done / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$done of $total done today', style: text.bodyMedium),
            Text(
              '${(fraction * 100).round()}%',
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(value: fraction, minHeight: 6),
        ),
      ],
    );
  }
}