import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/presentation/task_labels.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/check_button.dart';

enum _TaskMenu { edit, focus, delete }

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    super.key,
    this.category,
  });

  final Task task;
  final Category? category;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = task.isCompleted;
    final cat = category;
    final minutes = task.estimatedMinutes;
    final start = task.startAt;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xs),
      onTap: onEdit,
      child: Row(
        children: [
          CheckButton(done: done, onTap: onToggle),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textMuted,
                      color: done
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: 4,
                    children: [
                      if (cat != null)
                        _Meta(
                          leading: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(cat.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          label: cat.name,
                        ),
                      if (start != null)
                        _Meta(
                          leading: Icon(
                            task.reminderMinutesBefore != null
                                ? Icons.notifications_active_rounded
                                : Icons.alarm_rounded,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          label: timeLabel(start),
                        ),
                      _Meta(
                        leading: Icon(
                          Icons.flag_rounded,
                          size: 13,
                          color: task.priority.color,
                        ),
                        label: task.priority.label,
                      ),
                      if (minutes != null)
                        _Meta(
                          leading: const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          label: formatMinutes(minutes),
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
              color: AppColors.primary.withValues(alpha: done ? 0.08 : 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '+${task.xpReward} XP',
              style: text.labelSmall?.copyWith(
                color: done ? AppColors.textMuted : AppColors.primaryLight,
              ),
            ),
          ),
          PopupMenuButton<_TaskMenu>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (value) {
              switch (value) {
                case _TaskMenu.edit:
                  onEdit();
                case _TaskMenu.focus:
                  context.push(AppRoutes.focusForTask(task.id));
                case _TaskMenu.delete:
                  onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: _TaskMenu.edit, child: Text('Edit')),
              if (!done)
                const PopupMenuItem(
                  value: _TaskMenu.focus,
                  child: Text('Start focus'),
                ),
              const PopupMenuItem(value: _TaskMenu.delete, child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.leading, required this.label});

  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: AppColors.textSecondary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}