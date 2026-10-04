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
import 'package:ascend/shared/widgets/empty_state.dart';
import 'package:ascend/shared/widgets/error_state.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Planner')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              _DayHeader(
                title: _title(key, today),
                subtitle: longDate(_day),
                showToday: !isToday,
                onPrevious: () => _shift(-1),
                onNext: () => _shift(1),
                onToday: _goToday,
              ),
              Expanded(
                child: tasksAsync.when(
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => ErrorState(
                    message: 'Could not load tasks.',
                    onRetry: () => ref.invalidate(tasksByDayProvider(key)),
                  ),
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return EmptyState(
                        icon: Icons.checklist_rounded,
                        title: 'No tasks for this day',
                        message: 'Plan your day to start earning XP.',
                        actionLabel: 'Add task',
                        onAction: () => openTaskForm(
                          context,
                          initialDayKey: key,
                        ),
                      );
                    }
                    final done = tasks.where((t) => t.isCompleted).length;
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        96,
                      ),
                      itemCount: tasks.length + 1,
                      separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _Summary(done: done, total: tasks.length);
                        }
                        final task = tasks[index - 1];
                        return TaskCard(
                          key: ValueKey(task.id),
                          task: task,
                          category: categoryById[task.categoryId],
                          onToggle: () => toggleTask(context, ref, task),
                          onEdit: () => openTaskForm(
                            context,
                            task: task,
                            initialDayKey: key,
                          ),
                          onDelete: () => confirmDeleteTask(context, ref, task),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$done of $total completed', style: text.bodyMedium),
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