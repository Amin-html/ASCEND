import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';
import 'package:ascend/features/habits/domain/habit_streak.dart';
import 'package:ascend/features/habits/presentation/habit_labels.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/check_button.dart';

enum _HabitMenu { edit, archive, delete }

class HabitCard extends StatelessWidget {
  const HabitCard({
    required this.progress,
    required this.today,
    required this.onToggle,
    super.key,
    this.onEdit,
    this.onArchive,
    this.onDelete,
    this.showWeek = false,
    this.archived = false,
  });

  final HabitProgress progress;
  final DateTime today;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final bool showWeek;
  final bool archived;

  bool get _hasMenu => onEdit != null || onArchive != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final habit = progress.habit;
    final todayKey = dayKeyOf(today);
    final done = progress.isDoneOn(todayKey);
    final scheduledToday = habit.isScheduledOn(today);
    final streak = calculateHabitStreak(
      doneDays: progress.doneDays,
      weekdaysMask: habit.weekdaysMask,
      today: todayKey,
    );
    final description = habit.description;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        children: [
          Row(
            children: [
              if (archived)
                const SizedBox(width: AppSpacing.md)
              else if (scheduledToday)
                CheckButton(
                  key: ValueKey('habit-check-${habit.id}'),
                  done: done,
                  onTap: onToggle,
                )
              else
                const Tooltip(
                  message: 'Rest day',
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.bedtime_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                      if (description != null)
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: 4,
                        children: [
                          _Meta(
                            icon: Icons.event_repeat_rounded,
                            iconColor: AppColors.textMuted,
                            label: scheduleLabel(habit.weekdaysMask),
                          ),
                          _Meta(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: streak.current > 0
                                ? AppColors.warning
                                : AppColors.textMuted,
                            label: streakLabel(streak.current),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: done ? 0.08 : 0.16,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '+${habit.xpReward} XP',
                  style: text.labelSmall?.copyWith(
                    color: done ? AppColors.textMuted : AppColors.primaryLight,
                  ),
                ),
              ),
              if (_hasMenu)
                PopupMenuButton<_HabitMenu>(
                  tooltip: 'More',
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (value) {
                    switch (value) {
                      case _HabitMenu.edit:
                        onEdit?.call();
                      case _HabitMenu.archive:
                        onArchive?.call();
                      case _HabitMenu.delete:
                        onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _HabitMenu.edit,
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: _HabitMenu.archive,
                      child: Text(archived ? 'Restore' : 'Archive'),
                    ),
                    const PopupMenuItem(
                      value: _HabitMenu.delete,
                      child: Text('Delete'),
                    ),
                  ],
                )
              else
                const SizedBox(width: AppSpacing.sm),
            ],
          ),
          if (showWeek && !archived)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: _WeekStrip(
                habit: habit,
                doneDays: progress.doneDays,
                today: today,
              ),
            ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.habit,
    required this.doneDays,
    required this.today,
  });

  final Habit habit;
  final Set<String> doneDays;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final created = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    final days = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final d in days)
          _DayDot(
            letter: weekdayLetters[d.weekday - 1],
            done: doneDays.contains(dayKeyOf(d)),
            scheduled: habit.isScheduledOn(d) && !d.isBefore(created),
            isToday: dayKeyOf(d) == dayKeyOf(today),
          ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.letter,
    required this.done,
    required this.scheduled,
    required this.isToday,
  });

  final String letter;
  final bool done;
  final bool scheduled;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final Widget dot;
    if (done) {
      dot = Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
      );
    } else if (scheduled) {
      dot = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isToday ? AppColors.primaryLight : AppColors.textMuted,
            width: 1.5,
          ),
        ),
      );
    } else {
      dot = const SizedBox(
        width: 22,
        height: 22,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.border,
            ),
            child: SizedBox(width: 6, height: 6),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          letter,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isToday
                ? AppColors.textPrimary
                : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        dot,
      ],
    );
  }
}