import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/notifications/presentation/notification_labels.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/presentation/task_interactions.dart';
import 'package:ascend/features/tasks/presentation/task_labels.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/empty_state.dart';
import 'package:ascend/shared/widgets/error_state.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(taskByIdProvider(taskId));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Task')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Task')),
        body: ErrorState(
          message: 'Could not load the task.',
          onRetry: () => ref.invalidate(taskByIdProvider(taskId)),
        ),
      ),
      data: (task) =>
      task == null ? const _NotFound() : _TaskContent(task: task),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      body: EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Task not found',
        message: 'It may have been deleted.',
        actionLabel: 'Go to planner',
        onAction: () => context.go(AppRoutes.planner),
      ),
    );
  }
}

enum _DetailMenu { edit, delete }

class _TaskContent extends ConsumerWidget {
  const _TaskContent({required this.task});

  final Task task;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final deleted = await confirmDeleteTask(context, ref, task);
    if (deleted) await navigator.maybePop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    Category? category;
    for (final c in categories) {
      if (c.id == task.categoryId) category = c;
    }

    final done = task.isCompleted;
    final dayKey = task.dayKey;
    final start = task.startAt;
    final lead = task.reminderMinutesBefore;
    final estimated = task.estimatedMinutes;
    final actual = task.actualMinutes;
    final description = task.description;
    final completedAt = task.completedAt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          PopupMenuButton<_DetailMenu>(
            tooltip: 'More',
            onSelected: (value) {
              switch (value) {
                case _DetailMenu.edit:
                  openTaskForm(
                    context,
                    task: task,
                    initialDayKey: task.dayKey,
                  );
                case _DetailMenu.delete:
                  _delete(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _DetailMenu.edit, child: Text('Edit')),
              PopupMenuItem(value: _DetailMenu.delete, child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              AppCard(
                glow: !done,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: text.titleLarge?.copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textMuted,
                        color:
                        done ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _Chip(label: task.status.label, color: task.status.color),
                        _Chip(
                          label: '+${task.xpReward} XP',
                          color: AppColors.primaryLight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.folder_outlined,
                      label: 'Category',
                      value: category?.name ?? 'None',
                    ),
                    _InfoRow(
                      icon: Icons.flag_rounded,
                      label: 'Priority',
                      value: task.priority.label,
                    ),
                    _InfoRow(
                      icon: Icons.event_rounded,
                      label: 'Date',
                      value: dayKey == null
                          ? 'No date'
                          : shortDate(dateFromDayKey(dayKey)),
                    ),
                    _InfoRow(
                      icon: Icons.alarm_rounded,
                      label: 'Time',
                      value: start == null
                          ? 'Not set'
                          : '${timeLabel(start)}  •  '
                          '${lead == null ? 'No reminder' : reminderLabel(lead)}',
                    ),
                    _InfoRow(
                      icon: Icons.schedule_rounded,
                      label: 'Estimate',
                      value: estimated == null
                          ? 'Not set'
                          : formatMinutes(estimated),
                    ),
                    if (actual != null && actual > 0)
                      _InfoRow(
                        icon: Icons.timer_rounded,
                        label: 'Focused',
                        value: formatMinutes(actual),
                      ),
                    if (completedAt != null)
                      _InfoRow(
                        icon: Icons.check_circle_rounded,
                        label: 'Finished',
                        value: longDate(completedAt.toLocal()),
                      ),
                  ],
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description', style: text.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        description,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: () => toggleTask(context, ref, task),
                icon: Icon(done ? Icons.undo_rounded : Icons.check_rounded),
                label: Text(done ? 'Reopen' : 'Mark as done'),
              ),
              if (!done) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.focusForTask(task.id)),
                  icon: const Icon(Icons.timer_rounded),
                  label: const Text('Start focus'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: color),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}