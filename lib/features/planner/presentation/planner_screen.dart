import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/presentation/task_card.dart';
import 'package:ascend/features/tasks/presentation/task_interactions.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/count_up_text.dart';
import 'package:ascend/shared/widgets/empty_state.dart';
import 'package:ascend/shared/widgets/error_state.dart';
import 'package:ascend/shared/widgets/fade_slide_in.dart';
import 'package:ascend/shared/widgets/gradient_progress_bar.dart';
import 'package:ascend/shared/widgets/page_header.dart';
import 'package:ascend/shared/widgets/split_row.dart';

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider).now();
    _day = DateTime(now.year, now.month, now.day);
  }

  void _shift(int days) {
    setState(() => _day = DateTime(_day.year, _day.month, _day.day + days));
  }

  void _select(DateTime day) {
    setState(() => _day = DateTime(day.year, day.month, day.day));
  }

  void _goToday() {
    final now = ref.read(clockProvider).now();
    setState(() => _day = DateTime(now.year, now.month, now.day));
  }

  String _title(String key, DateTime today) {
    if (key == dayKeyOf(today)) return 'Today';
    if (key == dayKeyOf(DateTime(today.year, today.month, today.day + 1))) {
      return 'Tomorrow';
    }
    if (key == dayKeyOf(DateTime(today.year, today.month, today.day - 1))) {
      return 'Yesterday';
    }
    return weekdayName(_day);
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider).now();
    final today = DateTime(now.year, now.month, now.day);
    final key = dayKeyOf(_day);
    final isToday = key == dayKeyOf(today);
    final tasksAsync = ref.watch(tasksByDayProvider(key));
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final categoryById = {for (final c in categories) c.id: c};

    Widget padded(Widget child, {double bottom = AppSpacing.md}) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        bottom,
      ),
      child: child,
    );

    final content = tasksAsync.when<List<Widget>>(
      loading: () => const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, stack) => [
        ErrorState(
          message: 'Could not load tasks.',
          onRetry: () => ref.invalidate(tasksByDayProvider(key)),
        ),
      ],
      data: (tasks) {
        if (tasks.isEmpty) {
          return [
            EmptyState(
              icon: Icons.checklist_rounded,
              title: 'No tasks for this day',
              message: 'Plan your day to start earning XP.',
              actionLabel: 'Add task',
              onAction: () => openTaskForm(context, initialDayKey: key),
            ),
          ];
        }
        final done = tasks.where((t) => t.isCompleted).length;
        return [
          padded(_Summary(done: done, total: tasks.length)),
          for (var i = 0; i < tasks.length; i++)
            padded(
              FadeSlideIn(
                key: ValueKey(tasks[i].id),
                delay: Duration(milliseconds: 40 * (i > 8 ? 8 : i)),
                child: TaskCard(
                  task: tasks[i],
                  category: categoryById[tasks[i].categoryId],
                  onToggle: () => toggleTask(context, ref, tasks[i]),
                  onEdit: () => openTaskForm(
                    context,
                    task: tasks[i],
                    initialDayKey: key,
                  ),
                  onDelete: () => confirmDeleteTask(context, ref, tasks[i]),
                ),
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
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                const PageHeader(title: 'Planner'),
                _WeekStrip(selected: _day, today: today, onSelect: _select),
                _DayHeader(
                  title: _title(key, today),
                  subtitle: longDate(_day),
                  showToday: !isToday,
                  onPrevious: () => _shift(-1),
                  onNext: () => _shift(1),
                  onToday: _goToday,
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

/// Неделя (пн–вс) выбранного дня: быстрый переход на любой день.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.selected,
    required this.today,
    required this.onSelect,
  });

  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final monday = DateTime(
      selected.year,
      selected.month,
      selected.day - (selected.weekday - 1),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _DayChip(
                day: DateTime(monday.year, monday.month, monday.day + i),
                selected: _sameDay(
                  DateTime(monday.year, monday.month, monday.day + i),
                  selected,
                ),
                isToday: _sameDay(
                  DateTime(monday.year, monday.month, monday.day + i),
                  today,
                ),
                onTap: onSelect,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadius.control);
    final Color labelColor;
    final Color numberColor;
    if (selected) {
      labelColor = Colors.white.withValues(alpha: 0.85);
      numberColor = Colors.white;
    } else if (isToday) {
      labelColor = AppColors.primaryLight;
      numberColor = AppColors.primaryLight;
    } else {
      labelColor = AppColors.textMuted;
      numberColor = AppColors.textPrimary;
    }

    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.surfaceElevated,
          borderRadius: radius,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : isToday
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.border,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: () => onTap(day),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _weekdayShort[day.weekday - 1],
                      maxLines: 1,
                      style: text.labelSmall?.copyWith(color: labelColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      maxLines: 1,
                      style: text.titleMedium?.copyWith(color: numberColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.title,
    required this.subtitle,
    required this.showToday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final String title;
  final String subtitle;
  final bool showToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(title, style: text.titleLarge),
                Text(
                  subtitle,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (showToday)
            TextButton(onPressed: onToday, child: const Text('Today')),
          IconButton(
            tooltip: 'Next day',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fraction = total == 0 ? 0.0 : done / total;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SplitRow(
            left: Text('$done of $total completed', style: text.bodyMedium),
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
