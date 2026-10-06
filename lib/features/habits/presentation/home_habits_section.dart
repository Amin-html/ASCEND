import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/habits/data/habit_providers.dart';
import 'package:ascend/features/habits/presentation/habit_card.dart';
import 'package:ascend/features/habits/presentation/habit_interactions.dart';
import 'package:ascend/shared/widgets/app_card.dart';

const _maxHabitsOnHome = 5;

class HomeHabitsSection extends ConsumerWidget {
  const HomeHabitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider).now();
    final todayKey = dayKeyOf(now);
    final async = ref.watch(habitsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Habits', style: text.titleLarge),
            TextButton(
              onPressed: () => context.push(AppRoutes.habits),
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Text(
            'Could not load habits.',
            style: text.bodyMedium?.copyWith(color: AppColors.danger),
          ),
          data: (all) {
            final active = all.where((p) => !p.habit.isArchived).toList();

            if (active.isEmpty) {
              return AppCard(
                onTap: () => createHabit(context),
                child: Row(
                  children: [
                    const Icon(Icons.repeat_rounded, color: AppColors.primaryLight),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No habits yet', style: text.titleMedium),
                          Text(
                            'Small daily actions build big streaks.',
                            style: text.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => createHabit(context),
                      child: const Text('Add habit'),
                    ),
                  ],
                ),
              );
            }

            final scheduled =
            active.where((p) => p.habit.isScheduledOn(now)).toList();
            if (scheduled.isEmpty) {
              return Text(
                'No habits scheduled today.',
                style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
              );
            }

            return Column(
              children: [
                for (final p in scheduled.take(_maxHabitsOnHome))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: HabitCard(
                      key: ValueKey(p.habit.id),
                      progress: p,
                      today: now,
                      onToggle: () =>
                          toggleHabitToday(context, ref, p, todayKey),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}