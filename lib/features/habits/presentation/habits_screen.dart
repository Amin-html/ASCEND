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
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/count_up_text.dart';
import 'package:ascend/shared/widgets/empty_state.dart';
import 'package:ascend/shared/widgets/error_state.dart';
import 'package:ascend/shared/widgets/fade_slide_in.dart';
import 'package:ascend/shared/widgets/gradient_progress_bar.dart';
import 'package:ascend/shared/widgets/segment_control.dart';
import 'package:ascend/shared/widgets/split_row.dart';

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

    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: child,
    );

    final content = async.when<List<Widget>>(
      loading: () => const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, stack) => [
        ErrorState(
          message: 'Could not load habits.',
          onRetry: () => ref.invalidate(habitsProvider),
        ),
      ],
      data: (all) {
        final list =
            all.where((p) => p.habit.isArchived == _showArchived).toList();

        if (list.isEmpty) {
          return [
            _showArchived
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
                  ),
          ];
        }

        final scheduled = _showArchived
            ? const <HabitProgress>[]
            : list.where((p) => p.habit.isScheduledOn(now)).toList();
        final done = scheduled.where((p) => p.isDoneOn(todayKey)).length;

        return [
          if (scheduled.isNotEmpty)
            padded(_TodaySummary(done: done, total: scheduled.length)),
          for (var i = 0; i < list.length; i++)
            padded(
              FadeSlideIn(
                key: ValueKey(list[i].habit.id),
                delay: Duration(milliseconds: 40 * (i > 8 ? 8 : i)),
                child: HabitCard(
                  progress: list[i],
                  today: now,
                  showWeek: true,
                  archived: _showArchived,
                  onToggle: () =>
                      toggleHabitToday(context, ref, list[i], todayKey),
                  onEdit: () => editHabit(context, list[i].habit),
                  onArchive: () => setHabitArchived(
                    context,
                    ref,
                    list[i].habit,
                    archived: !_showArchived,
                  ),
                  onDelete: () => confirmDeleteHabit(context, ref, list[i]),
                ),
              ),
            ),
        ];
      },
    );

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
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: SegmentControl<bool>(
                  segments: const [(false, 'Active'), (true, 'Archived')],
                  selected: _showArchived,
                  onChanged: (value) => setState(() => _showArchived = value),
                ),
              ),
              ...content,
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

    return AppCard(
      glow: total > 0 && done == total,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SplitRow(
            left: Text('$done of $total done today', style: text.bodyMedium),
            right: CountUpText(
              value: (fraction * 100).round(),
              suffix: '%',
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GradientProgressBar(value: fraction),
        ],
      ),
    );
  }
}
